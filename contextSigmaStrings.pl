=head1 NAME

contextSigmaStrings.pl - Value object whose answers are list of strings from an alphabet Sigma

=head1 DESCRIPTION

This creates a Value object which is an unordered list of strings.

	loadMacros('contextSigmaStringss.pl');
	Context('SigmaStrings');
	$ans = Compute('11,10,01,010,110,101');
	$ans->char_list('01');

This object will accept that list of strings in any order. Gives a warning
message if any character except 0 and 1 is used. Also gives messages about
which strings are incorrect in the list.

=cut

sub _contextSigmaStrings_init {
	my $context = $main::context{SigmaStrings} = Parser::Context->getCopy("Numeric");
	$context->{name} = "SigmaStrings";
	$context->parens->clear();
	$context->variables->clear();
	$context->constants->clear();
	$context->operators->clear();
	$context->functions->clear();
	$context->strings->clear();
	$context->{pattern}{number} = "^\$";
	$context->variables->{patterns} = {};
	$context->strings->{patterns}{"(.|\n)*"} = [-20,'str'];
	$context->{value}{"String()"} = "context::SigmaStrings";
	$context->{value}{"String"} = "context::SigmaStrings::Value::String";
	$context->{parser}{String} = "context::SigmaStrings::Parser::String";
	$context->flags->set(noLaTeXstring => "\\longleftarrow");
	$context->update;
}

# Handle creating String() constants
package context::SigmaStrings;
sub new {shift; main::Compute(@_)}

# Replacement for Parser::String that uses the original string verbatim
# (but replaces \r and \r\n by \n to handle different browser multiline input)
package context::SigmaStrings::Parser::String;
our @ISA = ('Parser::String');

sub new {
	my $self = shift;
	my ($equation,$value,$ref) = @_;
	$value = $equation->{string};
	$value =~ s/\r\n?/\n/g;
	$self->SUPER::new($equation,$value,$ref);
}


# Replacement for Value::String that creates preview strings
# and includes the list checker.
package context::SigmaStrings::Value::String;
our @ISA = ("Value::String");

sub char_list {
	$self  = shift;
	$value = shift;
	return $self->{char_list} unless (defined($value));
	$self->{char_list} = $value;
}

sub TeX {
	my $self = shift;
	my $value = $self->value;
	$value =~ s/ //g;
	my @values = split(',', $value);
	if (length($value) > 30) {
		my $out = '\begin{array}{l}';
		my $i = 0;
		while ($i < scalar @values) {
			my $s = 0;
			while ($i < scalar @values && $s < 20) {
				$s += length($values[$i]);
				$out .= "\\text{$values[$i]},";
				$i++;
			}
			chop($out) if ($i == scalar @values);
			$out .= "\\\\";
		}
		$out .= '\end{array}';
		return $out;
	}
	return join(',', map { "\\text{$_}" } @values);
}

sub string {
	my $self = shift;
	my $value = $self->value;
	$value =~ s/,/, /g;
	return $value;
}

sub cmp_preprocess {
	my $self = shift;
	my $ans  = shift;
	if ($self->getFlag("noLaTeXresults")) {
		$ans->{preview_latex_string} = $self->getFlag("noLaTeXstring");
		$ans->{correct_ans_latex_string} = "";
	} else {
		$ans->{preview_latex_string} = $ans->{student_value}->TeX
			if defined $ans->{student_value};
		$ans->{correct_ans_latex_string} = $self->TeX($ans->{correct_ans});
	}
	$ans->{student_ans} = $ans->{student_value}->string
		if defined $ans->{student_value};
	$ans->{preview_text_string} = $ans->{student_ans};
	$ans->{preview_text_string} =~ s/,/, /g;
	return $ans;
}

sub num_word {
	my $self = shift;
	my $value = shift;
	if ($value > 18) {
		$value++;
		my $suffix = 'th';
		$suffix = 'st' if ($value % 10 == 1);
		$suffix = 'nd' if ($value % 10 == 2);
		$suffix = 'rd' if ($value % 10 == 3);
		return "$value$suffix";
	}
	return ('first', 'second', 'third', 'fourth', 'fifth', 'sixth', 'seventh', 'eighth',
		'ninth', 'tenth', 'eleventh', 'twelfth', 'thirteenth', 'fourteenth',
		'fifteenth', 'sixteenth', 'seventeenth', 'eighteenth', 'nineteenth')[$value];
}

sub cmp_postprocess {
	my $self = shift;
	my $ans  = shift;
	return $ans if $ans->{isPreview};

	my $s = $ans->{student_value};
	my $c = $self->value;
	$s =~ s/\s//g;

	my $chars = $self->{char_list};
	if (defined($chars) && $s =~ /[^$chars,]/) {
		$ans->{ans_message} = 'Strings can only contain the characters: ' . join(', ', split('', $chars));
		return $ans;
	}

	my @clist   = split(',', $c);
	my @slist   = split(',', $s);
	my $n       = scalar(@slist);
	my $nCor    = scalar(@clist);
	my $found   = {};
	my $nfound  = 0;
	my @errors  = ();
	my $nerrors = 0;
	for ($i = 0; $i < $n; $i++) {
		if ($found{$slist[$i]}) {
			$nerrors++;
			push(@errors, 'The ' . $self->num_word($i) . ' string is a repeat.');
		} elsif (grep(/^$slist[$i]$/, @clist)) {
			$found{"$slist[$i]"} = 1;
			$nfound++;
		} else {
			$nerrors++;
			push(@errors, 'The ' . $self->num_word($i) . ' string is incorrect.');
		}
	}
	if (scalar(@errors) > 2) {
		@errors = ('You have multiple incorrect bitstrings.');
	} elsif ($n < $nCor) {
		push(@errors, 'You are missing items in your list.');
	}
	if ($ans->{showEqualErrors}) {
		$ans->{ans_message} = join($main::BR, @errors);
	}
	if ($ans->{partialCredit}) {
		$ans->{score} = ($nfound > $nerrors) ? ($nfound - $nerrors) / $nCor : 0;
	} else {
		$ans->{score} = ($nerrors == 0 && $nfound == $nCor) ? 1 : 0;
	}
	return $ans;
};

1;
