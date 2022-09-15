# Walk checker:
# This works with ArbitraryStrings and is a parser that will check if walks
# meet certain conditions and produce error messages if any issue is found.
# You need to supply the grader a reference to the array of labels and the
# adjacency matrix. Other options configure what the grader accepts/rejects.
#   labels           Reference to array of vertex labels.
#   adj_mat          Reference to adjacency matrix array.
#   start_vertex     Label of the starting vertex. If no label is provided, can start at any vertex.
#   end_vertex       Label of ending vertex. If no label is provided, can end at any vertex.
#   min_length       The minimum length (number of edges) of the walk.
#   min_vertices     The minimum number of unique vertices in the walk.
#   unique_vertices  Force the walk to use unique vertices (first vertex is not counted for cycles).
#   count_start      Count the start vertex when looking for unique vertices on closed walks.
#   unique_edges     Force the walk to use unique edges.
#   dup_vertices     Force the walk to use duplicate vertices (first is ignored unless count_start is set).
#   dup_edges        Force the walk to use duplicate edges.
#   force_open       Force the walk to be open.
#   force_closed     Force the walk to be closed.
#   hide_invalid     Hide messages about using invalid vertices or edges in walk.
#   hide_errors      Hide messages about the walk meeting desired options.
$walkcmp = sub {
	my ($cor, $stu, $ans) = @_;
	return 0 if $ans->{isPreview};
	my $start = $ans->{start_vertex};
	my $end = $ans->{end_vertex};
	my $labels = $ans->{labels};
	my %lnum = map { $labels->[$_] => $_ } (0..scalar(@$labels)-1);
	my $adjMat = $ans->{adj_mat};
	my $allowed = join('', @$labels);
	$stu = $stu->value;
	$stu =~ s/\s//g;
	Value->Error('The walk can only include the vertices shown in the graph.') if ($stu =~ /[^$allowed,]/);
	my @walk = split(',', $stu);
	my $minL = $ans->{min_length} || 1;
	my @msg = ();
	push(@msg, "The walk must have at least $minL edges.") if ($#walk < $minL);
	push(@msg, "The walk must start at vertex $start") if (defined($start) && $walk[0] ne $start);
	push(@msg, "The walk must end at the vertex $end") if (defined($end) && $walk[-1] ne $end);
	if (scalar @msg > 0) {
		Value->Error($msg[0]) unless $ans->{hide_errors};
		return 0;
	}
 
	my %verts = (); # Don't count starting vertex initially.
	my %edges = ();
	foreach my $i (0..$#walk-1) {
		my $v1 = $lnum{$walk[$i]};
		my $v2 = $lnum{$walk[$i+1]};
		push(@msg, $walk[$i] . ' is not a valid vertex.') unless defined($v1);
		push(@msg, $walk[$i+1] . ' is not a valid vertex.') unless defined($v2);
		push(@msg, 'There is no edge between ' . $walk[$i] . ' and ' . $walk[$i+1] . '.') unless ($adjMat->[$v1][$v2]);
		if (scalar @msg > 0) {
			Value->Error($msg[0]) unless $ans->{hide_errors};
			return 0;
		}
		$verts{$walk[$i+1]}++;
		$edges{join('', lex_sort($walk[$i], $walk[$i+1]))}++;
	}
	my $isClosed = ($walk[0] eq $walk[-1]);
	my $isOpen   = 1 - $isClosed;
	$verts{$walk[0]}++ if ($ans->{count_start} || $isOpen); # Count starting vertex if the walk is open or forced.
	my $dupEdges = 0;
	foreach my $key (keys %edges) {
		$dupEdges = 1 if ($edges{$key} > 1);
	}
	my $dupVerts = 0;
	foreach my $key (keys %verts) {
		$dupVerts = 1 if ($verts{$key} > 1);
	}
	push(@msg, 'The walk uses a vertex more than once.') if ($ans->{unique_vertices} && $dupVerts);
	push(@msg, 'The walk must use a vertex more than once.') if ($ans->{dup_vertices} && !$dupVerts);
	push(@msg, 'The walk uses an edge more than once.') if ($ans->{unique_edges} && $dupEdges);
	push(@msg, 'The walk must use an edge more than once.') if ($ans->{dup_edges} && !$dupEdges);
	push(@msg, 'The walk is not closed.') if ($ans->{force_closed} && $isOpen);
	push(@msg, 'The walk is not open.') if ($ans->{force_open} && $isClosed);
	$minV = $ans->{min_vertices} || 0;
	push(@msg, "The walk must use at least $minV unique vertices.") if (scalar(keys %verts) < $minV);
	if (scalar @msg > 0) {
		Value->Error($msg[0]) unless $ans->{hide_errors};
		return 0;
	}
	return 1;
};

