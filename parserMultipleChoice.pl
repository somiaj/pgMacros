################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2022 The WeBWorK Project, https://github.com/openwebwork
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME

parserMultipleChoice.pl - Multiple choice/select object compatible with Value objects.

=head1 DESCRIPTION

This file implements a multiple choice or select object that is compatible
with MathObjects, and in particular, with the MultiAnswer object, and with
PGML.

To create a MultipleChoice object, use

	$mc = MultipleChoice([choices,...], correct, labels);

where "choices" are the strings for the items in the answer list,
and "correct" are the string(s) (or index(s), with 0 being the first
one) of the correct choices. You can either input a single string
or a list of strings, [correct1, correct2, ...]. For example

	$radio = MultipleChoice(
		["First Item", "Second Item", ..., "Last Item"],
		"Second Item"
		);

will create a radio button list with a single correct answer and

	$checkbox = MultipleChoice(
		["First Item", "Second Item", ..., "Last Item"],
		["Second Item", "Last Item"]
	);

will create a checkbox list with multiple correct answers to select.
Note a correct list with a single item, ["Second Item"], will create
a checkbox list with a single correct answer.

Optionally, "labels" can either be a list, [label1, label2, ...],
of labels for the items or a string to generate automatic labels.
The string should contain a single character to identify label type:
lower case letters 'a', upper case letters 'A', numbers '1',
lower case roman numerals 'i', and upper case roman numerals 'I'.
Two specific options 'none' or 'list' will not print any labels
in the problem text, but still use labels in the answer string.
'none' uses the labels First item, Second item, and so on while
'list' uses the choice text for the label. Labels should be short
strings without special characters.

Additionally the "labels" character can have an optional character
before and after the label to put before and/or after the label during
generation. The default string is 'A.', capital letters followed by
a period. A string '(1)' will use numbers surrounded by parenthesis.
'I:' would be upper case roman numerals followed by a colon.

By default, the choices are left in the order that you provide them,
but you can cause some or all of them to be ordered randomly by
enclosing those that should be randomized within a second set of
brackets.  For example

	$radio = MultipleChoice(
		[
			"First Item",
			["Random 1","Random 2","Random 3"],
			"Last Item"
		],
		"Random 3"
	);

will make an answer list that has the first item always on top, the
next three ordered randomly, and the last item always on the bottom.
In this example

	$radio = MultipleChoice([["Random 1","Random 2","Random 3"]], 2);

all the entries are randomized, and the correct answer is "Random 3"
(the one with index 2 in the original, unrandomized list).  You can
have as many randomized groups, with as many static items in between,
as you want.

To insert the multiple choice list in PGML, use this like a MathObject

	BEGIN_PGML
	[_]{$mc}
	END_PGML

You can also insert the multiple choice list into the problem text and
call the answer checker.

	BEGIN_TEXT
	\{ $mc->ans_rule \}
	END_TEXT
	ANS($mc->cmp);

You can use the MultipleChoice object in MultiAnswer objects.  This is
the reason for the ans_rule method (since that is what MultiAnswer calls to
get answer rules).

=head1 OPTIONS

After the MultipleChoice object is created you can modify the object to gain
additional control. Since the labels show up in the TeX and PTX output modes,
be sure to to use PG variables or MODES instead of pure HTML.

$mc->updateLabels(labels)         Updates the labels according to a new string or
                                  list as described above.

$mc->{showLabels} = 1 (or 0)      Shows/hides the labels in the problem text.

$mc->{before} = "$BBOLD"          String to print before label in problem text.

$mc->{after} = "$EBOLD."          String to print after label in problem text.

$mc->{separator} = $BR            Print each button/checkbox on its own line in
                                  problem text.

ANS($mc->cmp(partialCredit => 1)) Grade problem as a list of true/false statements,
                                  and give partial credit as a ratio of the correctly
                                  selected/unselected items to the total number of items.
                                  Defaults to $showPartialCorrectAnswers.

=cut

loadMacros('MathObjects.pl');

sub _parserMultipleChoice_init {parser::MultipleChoice::Init()}; # don't reload this file

# The package that implements multiple choice/select lists.
package parser::MultipleChoice;
our @ISA = ('Value::String');
my $context;

#  Setup the context and the MultipleChoice() command.
sub Init {
	# Make a context in which arbitrary strings can be entered.
	$context = Parser::Context->getCopy('Numeric');
	$context->{name} = 'MultipleChoice';
	$context->parens->clear();
	$context->variables->clear();
	$context->constants->clear();
	$context->operators->clear();
	$context->functions->clear();
	$context->strings->clear();
	$context->{pattern}{number} = '^\$';
	$context->variables->{patterns} = {};
	$context->strings->{patterns}{'.*'} = [-20,'str'];
	$context->{parser}{String} = 'parser::MultipleChoice::String';
	$context->update;
	main::PG_restricted_eval('sub MultipleChoice {parser::MultipleChoice->new(@_)}');
}

# Create a new MultipleChoice object.
sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	shift if Value::isContext($_[0]); # remove context, if given (it is not used)
	my $choices = shift;
	my $values  = shift;
	my $labels  = shift;
	Value->Error("A MultipleChoice's first argument should be a list of items")
		unless ref($choices) eq 'ARRAY';
	Value->Error("A MultipleChoice's second argument should be the correct choice(s)")
		unless defined($values) && $values ne "";

	$self = bless {
		data        => [],
		context     => $context,
		choices     => $choices,
		correct     => [],
		before      => $main::BBOLD,
		after       => "${main::EBOLD}.",
		separator   => $main::BR,
		checkboxes  => 1,
		showLabels  => 1,
		attempts    => 0,
		maxAttempts => 0,
		attemptStr  => 'xN',
		trackChange => 0,
		answers     => [],
		name        => undef,
	}, $class;
	$self->getChoiceOrder;
	$self->getCorrectAns($choices, $values);
	$self->updateLabels($labels);

	return $self;
}


# List getters
sub answers {@{ shift->{answers} }}
sub correct {@{ shift->{correct} }}
sub choices {@{ shift->{choices} }}
sub labels {
	my $self = shift;
	my $i    = shift;
	return (defined($i) && defined($self->{labels}->[$i])) ? $self->{labels}->[$i] : @{$self->{labels}};
}
sub correct_ans {
	my $self = shift;
	return @{ $self->{labels} }[@{ $self->{correct} }];
}

# Get the choices into the desired order (randomizing where requested).
sub getChoiceOrder {
	my $self    = shift;
	my @choices = ();
	foreach my $choice (@{$self->{choices}}) {
		if (ref($choice) eq "ARRAY") {
			push(@choices,$self->randomOrder($choice))
		} else {
			push(@choices,$choice)
		}
	}
	$self->{choices} = \@choices;
}
sub randomOrder {
	my $self    = shift;
	my $choices = shift;
	my %index   = (map {$main::PG_random_generator->rand => $_} (0..scalar(@$choices)-1));
	return (map {$choices->[$index{$_}]} main::PGsort(sub {$_[0] lt $_[1]}, keys %index));
}

# Find the correct answer(s)
sub getCorrectAns {
	my $self    = shift;
	my $choices = shift;
	my $values  = shift;
	my @correct = ();
	my @order   = map {ref($_) eq "ARRAY" ? @$_ : $_} @$choices;
	my %choice; @choice{@{$self->{choices}}} = 1..scalar @{$self->{choices}};
	if (ref($values) ne 'ARRAY') {
		$values = [$values];
		$self->{checkboxes} = 0;
	}
	foreach my $value (@$values) {
		if ($choice{$value}) {
			push(@correct, $choice{$value} - 1);
		} elsif ($value =~ m/^\d+$/ && $order[$value]) {
			push(@correct, $choice{$order[$value]} - 1);
		} else {
			Value->Error('The correct choice must be one of the MultipleChoice items');
		}
	}
	$self->{correct} = [main::num_sort(@correct)];
	return;
}

# Create labels for each item in the list.
sub updateLabels {
	my $self     = shift;
	my $labels   = shift || '';
	my @charList = ();

	if (ref($labels) eq 'ARRAY') { # TODO: Add protection for special characters and/or length in user provided lists
		@charList = (@$labels);
		Value->Error('You must supply enough labels for all items.') unless ($#charList > $#{$self->{choices}});
	} elsif (defined($labels) && uc($labels) eq 'NONE') {
		$self->{showLabels} = 0;
		@charList = ('First item', 'Second item', 'Third item', 'Fourth item', 'Fifth item',
				'Sixth item', 'Seventh item', 'Eighth item', 'Ninth item', 'Tenth item',
				'Eleventh item', 'Twelfth item', 'Thirteenth item', 'Fourteenth item',
				'Fifteenth item', 'Sixteenth item', 'Seventeenth item', 'Eighteenth item');
	} elsif (defined($labels) && uc($labels) eq 'LIST') { # TODO: Add protection to user provided list
		$self->{showLabels} = 0;
		@charList = (@{$self->{choices}});
	} elsif (defined($labels) && $labels =~ /^(.)?(\w)(.)?$/) {
		$self->{before} = $main::BBOLD . $1 if $1;
		my $char        = $2;
		$self->{after}  = $3 . $main::EBOLD if $3;
		if ($char =~ /[ivx]/) {
			@charList = ('i', 'ii', 'iii', 'iv', 'v', 'vi', 'vii', 'viii', 'ix', 'x',
				'xi', 'xii', 'xiii', 'xiv', 'xv', 'xvi', 'xvii', 'xviii', 'xix', 'xx');
		} elsif ($char =~ /[IVX]/) {
			@charList = ('I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
				'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII', 'XIX', 'XX');
		} elsif ($char =~ /[a-z]/) {
			@charList = (a..z);
		} elsif ($char =~ /\d/) {
			@charList = (1..20);
		} else {
			@charList = (A..Z);
		}
	} else {
		@charList = (A..Z);
	}
	$self->{labels} = [@charList[0..$#{$self->{choices}}]];
	$self->{data}[0] = join(', ', $self->correct_ans);
	return;
}
sub printLabel {
	my $self = shift;
	my $i    = shift;
	return ' ' unless ($self->{showLabels});
	my $space = ($self->{checkboxes}) ? ' class="ms-1"' : '';
	if ($main::displayMode =~ m/^HTML/) {
		return "<span$space>" . $self->{before} . $self->labels($i) . $self->{after} . '</span> ';
	} else {
		return $self->{before} . $self->labels($i) . $self->{after};
	}
}

# Helpers
sub getName {
	my $self      = shift;
	my $name      = shift;
	$name         = defined($self->{name}) ? $self->{name} : main::NEW_ANS_NAME() unless $name;
	$self->{name} = $name;
	return $name;
}
sub getAnswers {
	my $self              = shift;
	my $name              = $self->{name};
	my $value             = defined($main::inputs_ref->{$name}) ? $main::inputs_ref->{$name} : '';
	$self->{answer_value} = $value;
	$self->{answers}      = [$self->getAnsList(1, $value)];
	return $value;
}
sub escapeAttempts {
	my $self  = shift;
	return $self->{attemptStr} . $self->{attempts};
}
sub getAttempts {
	my $self  = shift;
	my $value = shift;
	return -1 unless $value;
	my $as    = $self->{attemptStr};
	return $1 if ($value =~ /^$as(\d+)$/);
	return -1;
}
sub cmpList {
	my $self = shift;
	return 0 unless (scalar $self->answers > 0);
	return (join('', $self->correct_ans) eq join('', $self->answers));
}
sub cmpListTF {
	my $self    = shift;
	return 0 unless (scalar $self->answers > 0);
	my @labels  = $self->labels;
	my %student = map { $_ => 1 } $self->answers;
	my %correct = map { $_ => 1 } $self->correct_ans;
	my $score = 0;
	foreach (@labels) {
		$score++ unless (!$student{$_} != !$correct{$_});
	}
	return $score / scalar @labels;
}
sub getAnsList {
	my $self       = shift;
	my $type       = shift;
	my $answer_str = shift;
	my $split_str  = ('\x{fffd}', '\0', ', ')[$type];
	$answer_str    =~ s/^\[|\]$//g if ($type == 2);
	my @answers    = split($split_str, $answer_str);
	my $attempts   = $self->getAttempts($answers[-1]);
	if ($attempts != -1) {
		$self->{attempts} = $attempts if ($type == 1);
		pop(@answers);
	}
	return @answers;
}

# Prints the radio buttons or checkboxes and adds the
# number of attempts and previous answer hidden inputs.
sub PRINT_BUTTONS {
	my $self    = shift;
	my @buttons = @_;
	my $name    = $self->{name};
	my %answers = map { $_ => 1 } $self->answers;

	# Print button list
	my $label      = main::generate_aria_label($name);
	my $buttonType = ($self->{checkboxes}) ? 'checkbox' : 'radio';
	my $attempts   = $self->escapeAttempts;
	my @out        = ();
	my $count      = 0;
	while (@buttons) {
		my $value    = shift @buttons;
		my $item     = shift @buttons;
		my $checked  = ($answers{$self->labels($count)}) ? 'checked' : '';
		my $countstr = ($count) ? "_$count" : '';
		$count++;
		push(@out, qq!<label><input type="$buttonType" name="$name" id="${name}$countstr" aria-label="${label}option $count" value="$value" $checked>$item</label>!);
	}
	my $out_str = join("\n" . $self->{separator}, @out);
	$out_str .= qq!<input id="${name}_$self->{attemptStr}" type="hidden" name="$name" value="$attempts">! if $self->{trackAttempts};
	return $out_str;
}
sub PRINT {
	my $self    = shift;
	my $extend  = shift;
	my $name    = $self->getName(shift);
	my $size    = shift;
	my %options = @_;
	my $out     = '';
	my $value   = $self->getAnswers;
	if ($main::displayMode =~ m/^HTML/) {
		my @buttons = ();
		my $i       = 0;
		foreach ($self->choices) {
			push(@buttons, $self->labels($i), $self->printLabel($i) . "<span class='ms-2'>$_</span>");
			$i++;
		}
		$out = $self->PRINT_BUTTONS(@buttons);
		$out .= $self->JavaScript;
	} elsif ($main::displayMode eq 'PTX') {
		my $formType = $self->{checkboxes} ? 'checkboxes' : 'buttons';
		my $i        = 0;
		$out = qq(<var form="$formType" name="$name">) . "\n";
		foreach my $item (@list) {
			$out .= '<li>';
			my $escaped_item = $self->printLabel($i) . $item;
			$escaped_item =~ s/&/&amp;/g;
			$escaped_item =~ s/</&lt;/g;
			$escaped_item =~ s/>/&gt;/g;
			$out .= $escaped_item . '</li>'. "\n";
			$i++;
		}
		$out .= '</var>';
	} elsif ($main::displayMode eq "TeX") {
		# If the total number of characters is not more than
		# 30 and not containing / or ] then we print out
		# the select as a string: [A/B/C]
		my @labeledList = ();
		foreach $i (0..$#list) {
			push(@labeledList, $self->printLabel($i) . $list[$i]);
		}
		if (length(join('', @labeledList)) < 25 && !grep(/(\/|\[|\])/, @labeledList)) {
			$out = '[' . join('/', map {$self->quoteTeX($_)} @labeledList) . ']';
		} else {
			# Otherwise we print a bulleted list
			$out = '\par\vtop{\def\bitem{\hbox\bgroup\indent\strut\textbullet\ \ignorespaces}\let\eitem=\egroup';
			$out = "\n" . $out . "\n";
			foreach my $option (@labeledList) {
				$out .= '\bitem ' . $self->quoteTeX($option) . "\\eitem\n";
			}
			$out .= '\vskip3pt}' . "\n";
		}
	}
	main::RECORD_ANS_NAME($name, $value) unless $extend;
	main::INSERT_RESPONSE($options{answer_group_name}, $name, $value) if $extend;
	return $out;
}
# Javascript to count number of submits in which the answer changes
sub JavaScript {
	my $self = shift;
	return '' unless $self->{trackChange};
	my $as = $self->{attemptStr};
	my $name = $self->{name};
	my $thisId = $name . '_' . $as;
	return if $jsPrinted || $main::displayMode eq 'TeX';
	return '<script>' .
		"document.addEventListener('DOMContentLoaded', function() {" .
		"document.getElementById('problemMainForm').addEventListener('submit', function(e) {" .
		"document.getElementById('$thisId').value = '${as}7'; })});" .
		'</script>';
}

# Uses cmp_postprocess to remove the attempts from the answer
# and compare the students responses to the correct answer.
sub typeMatch { return 1; }
sub cmp_defaults {(
	shift->SUPER::cmp_defaults(@_),
	partialCredit => $main::showPartialCorrectAnswers,
)}
sub cmp_class {
	my $self = shift;
	return ($self->{checkboxes}) ? 'MultipleChoice checkboxes' : 'MultipleChoice radio buttons';
}
sub cmp_preprocess {
	my $self = shift;
	my $ans  = shift;

	# Update answer displays
	$ans->{student_ans} = join(', ', $self->answers);
	$ans->{original_student_ans} = $ans->{student_ans};
	$ans->{preview_latex_string} = "\\text{$ans->{student_ans}}";

	return $ans;
}
sub cmp_postprocess {
	my $self    = shift;
	my $ans     = shift;

	# Grade answer
	$ans->{score} = ($ans->{partialCredit} && $self->{checkboxes}) ? $self->cmpListTF : $self->cmpList;

	# Check attempts
	$ans->{ans_message} = "You have used $self->{attempts} attempts on this part." if $self->{trackAttempts};
	return $ans;
}

#  Answer rule is the multiple choice/select list
sub ans_rule {shift->PRINT(0, '', @_)}
sub named_ans_rule {shift->PRINT(0, @_)}
sub named_ans_rule_extension {shift->PRINT(1, @_)}

##################################################
#
#  Replacement for Parser::String that takes the
#  complete parse string as its value
#
package parser::MultipleChoice::String;
our @ISA = ('Parser::String');

sub new {
	my $self = shift;
	my ($equation, $value, $ref) = @_;
	$value = $equation->{string};
	$self->SUPER::new($equation, $value, $ref);
}

##################################################

1;
