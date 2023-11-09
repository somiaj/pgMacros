
sub _contextWalks_init {
	my $context = $main::context{Walks} = Parser::Context->getCopy("Numeric");
	$context->{name} = "Walks";
	$context->parens->clear();
	$context->variables->clear();
	$context->constants->clear();
	$context->operators->clear();
	$context->functions->clear();
	$context->strings->clear();
	$context->{pattern}{number}              = "^\$";
	$context->variables->{patterns}          = {};
	$context->strings->{patterns}{"(.|\n)*"} = [ -20, 'str' ];
	$context->{value}{"Walk()"}              = "context::Walks";
	$context->{value}{"String()"}            = "context::Walks";
	$context->{value}{"String"}              = "context::Walks::Value::String";
	$context->{parser}{String}               = "context::Walks::Parser::String";
	$context->flags->set(noLaTeXstring => "\\longleftarrow");
	$context->update;
}

#  Handle creating String() constants
package context::Walks;
sub new { shift; main::Compute(@_) }

#  Replacement for Parser::String that uses the original string verbatim
#  (but replaces \r and \r\n by \n to handle different browser multiline input)
package context::Walks::Parser::String;
our @ISA = ('Parser::String');

sub new {
	my $self = shift;
	my ($equation, $value, $ref) = @_;
	$value = $equation->{string};
	$value =~ s/\r\n?/\n/g;
	$self->SUPER::new($equation, $value, $ref);
}

#  Replacement for Value::String that adds the Walk grader.
package context::Walks::Value::String;
our @ISA = ("Value::String");

#  Mark a multi-line string to be displayed verbatim in TeX
sub quoteTeX {
	my $self = shift;
	my $s    = shift;
	return $self->verb($s) unless $s =~ m/\n/;
	my @tex = split(/\n/, $s);
	foreach (@tex) { $_ = $self->verb($_) if $_ =~ m/\S/ }
	"\\begin{array}{l}" . join("\\\\ ", @tex) . "\\end{array}";
}

#  Quote HTML special characters
sub quoteHTML {
	my $self = shift;
	my $s    = $self->SUPER::quoteHTML(shift);
	$s = "<pre style=\"text-align:left; padding-left:.2em\">$s</pre>"
		unless ($main::displayMode eq "TeX" or $main::displayMode eq "PTX");
	return $s;
}

#  Walk grader
sub cmp_preprocess {
	my $self = shift;
	my $ans  = shift;
	if ($self->getFlag("noLaTeXresults")) {
		$ans->{preview_latex_string}     = $self->getFlag("noLaTeXstring");
		$ans->{correct_ans_latex_string} = "";
	} else {
		$ans->{preview_latex_string} = $ans->{student_value}->TeX
			if defined $ans->{student_value};
	}
	$ans->{student_ans} = $self->quoteHTML($ans->{student_value}->string)
		if defined $ans->{student_value};
	return $ans if $ans->{isPreview};
	$ans = $self->cmp_walk($ans);
	return $ans;
}

# Walk checker:
# Context that checks if a Walk meets certain conditions:
# You need to supply the grader a reference to the array of labels and the
# adjacency matrix. Other options configure what the grader accepts/rejects.
#   labels           Reference to array of vertex labels.
#   adj_mat          Reference to adjacency matrix array.
#   start_vertex     Label of the starting vertex. If no label is provided, can start at any vertex.
#   end_vertex       Label of ending vertex. If no label is provided, can end at any vertex.
#   min_length       The minimum length (number of edges) of the walk.
#   min_vertices     The minimum number of unique vertices in the walk.
#   unique_vertices  Force the walk to use unique vertices (first vertex is not counted for cycles).
#   count_start      Count the start vertex when looking for unique vertices.
#   unique_edges     Force the walk to use unique edges.
#   dup_vertices     Force the walk to use duplicate vertices (first is ignored unless count_start is set).
#   dup_edges        Force the walk to use duplicate edges.
#   force_open       Force the walk to be open.
#   force_closed     Force the walk to be closed.
#   hide_errors      Hide messages about using invalid vertices or edges in walk.
#   hide_warnings    Hide messages about the walk meeting desired options.
sub cmp_walk {
	my $self    = shift;
	my $ans     = shift;
	my $stu     = $ans->{student_value};
	my $start   = $ans->{start_vertex};
	my $end     = $ans->{end_vertex};
	my $labels  = $ans->{labels};
	my $adjMat  = $ans->{adj_mat};
	my $allowed = join('', @$labels);
	my @msg     = ();

	# Initial checks: Invalid characters, Vertex length, Start/Stop Vertex.
	$stu =~ s/\s//g;
	my @walk = split(',', $stu);
	my $minL = $ans->{min_length} || 2;
	push(@msg, 'The answer includes invalid vertices.')       if ($stu =~ /[^$allowed,]/);
	push(@msg, "The walk must have at least $minL vertices.") if (scalar(@walk) < $minL);
	push(@msg, "The walk must start at vertex $start")        if (defined($start) && $walk[0] ne $start);
	push(@msg, "The walk must end at the vertex $end")        if (defined($end) && $walk[-1] ne $end);

	if (scalar @msg > 0) {
		$ans->{ans_message} = $msg[0] unless $ans->{hide_errors};
		return $ans;
	}

	# Traverse walk checking and counting each vertex and edge.
	my %verts = ();    # Note doesn't count first vertex initially.
	my %edges = ();
	foreach my $i (0 .. $#walk - 1) {
		my $v1 = $lnum{ $walk[$i] };
		my $v2 = $lnum{ $walk[ $i + 1 ] };
		push(@msg, $walk[$i] . ' is not a valid vertex.')       unless defined($v1);
		push(@msg, $walk[ $i + 1 ] . ' is not a valid vertex.') unless defined($v2);
		push(@msg, 'There is no edge between ' . $walk[$i] . ' and ' . $walk[ $i + 1 ] . '.')
			unless ($adjMat->[$v1][$v2]);
		if (scalar @msg > 0) {
			$ans->{ans_message} = $msg[0] unless $ans->{hide_errors};
			return $ans;
		}
		$verts{ $walk[ $i + 1 ] }++;
		$edges{ join('', main::lex_sort($walk[$i], $walk[ $i + 1 ])) }++;
	}

	# Walk characteristics: Open, Closed, Unique/Duplicate Edges/Vertices.
	my $isClosed = ($walk[0] eq $walk[-1]);
	my $isOpen   = 1 - $isClosed;
	$verts{ $walk[0] }++ if ($ans->{count_start} || $isOpen);    # Now count starting vertex if open or forced.
	my $dupEdges = 0;
	foreach my $key (keys %edges) {
		$dupEdges = 1 if ($edges{$key} > 1);
	}
	my $dupVerts = 0;
	foreach my $key (keys %verts) {
		$dupVerts = 1 if ($verts{$key} > 1);
	}
	push(@msg, 'The walk uses a vertex more than once.')     if ($ans->{unique_vertices} && $dupVerts);
	push(@msg, 'The walk must use a vertex more than once.') if ($ans->{dup_vertices}    && !$dupVerts);
	push(@msg, 'The walk uses an edge more than once.')      if ($ans->{unique_edges}    && $dupEdges);
	push(@msg, 'The walk must use an edge more than once.')  if ($ans->{dup_edges}       && !$dupEdges);
	push(@msg, 'The walk is not closed.')                    if ($ans->{force_closed}    && $isOpen);
	push(@msg, 'The walk is not open.')                      if ($ans->{force_open}      && $isClosed);
	$minV = $ans->{min_vertices} || 0;
	push(@msg, "The walk must use at least $minV unique vertices.") if (scalar(keys %verts) < $minV);

	if (scalar @msg > 0) {
		$ans->{ans_message} = $msg[0] unless $ans->{hide_warnings};
	} else {
		$ans->{score} = 1;
	}
	return $ans;
}

1;
