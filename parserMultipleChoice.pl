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

This is now just a wrapper for C<parserRadioButtons.pl> and
C<parserCheckboxList.pl>.

    $mc = MultipleChoice([@choices], $correct, $labels, @options);

If C<$correct> is an array reference, this will call C<parserCheckboxList.pl>,
and is equivalent to:

    $mc = CheckboxList([@choices], [@correct], @options);

Otherwise this will call C<parserRadioButtons.pl> and is equivalent to:

    $mc = RadioButtons([@choices], $correct, @options);

=cut

loadMacros('parserRadioButtons.pl', 'parserCheckboxList.pl');

# Create the appropriate MultipleChoice object.
sub MultipleChoice {
	my ($choices, $correct, $labels, @options) = @_;

	# $labels is ignored, just a place keeper from the old macro.
	return
		ref($correct) eq 'ARRAY'
		? CheckboxList($choices, $correct, @options)
		: RadioButtons($choices, $correct, @options);
}

# Create labels for each item in the list.
# Old function, keeping just in case.
#sub updateLabels {
#	my $self     = shift;
#	my $labels   = shift || '';
#	my @charList = ();
#
#	if (ref($labels) eq 'ARRAY') {    # TODO: Add protection for special characters and/or length in user provided lists
#		@charList = (@$labels);
#		Value->Error('You must supply enough labels for all items.') unless ($#charList >= $#{ $self->{choices} });
#	} elsif (defined($labels) && uc($labels) eq 'NONE') {
#		$self->{showLabels} = 0;
#		@charList = (
#			'First item',
#			'Second item',
#			'Third item',
#			'Fourth item',
#			'Fifth item',
#			'Sixth item',
#			'Seventh item',
#			'Eighth item',
#			'Ninth item',
#			'Tenth item',
#			'Eleventh item',
#			'Twelfth item',
#			'Thirteenth item',
#			'Fourteenth item',
#			'Fifteenth item',
#			'Sixteenth item',
#			'Seventeenth item',
#			'Eighteenth item'
#		);
#	} elsif (defined($labels) && uc($labels) eq 'LIST') {    # TODO: Add protection to user provided list
#		$self->{showLabels} = 0;
#		@charList = (@{ $self->{choices} });
#	} elsif (defined($labels) && $labels =~ /^(.)?(\w)(.)?$/) {
#		$self->{before} = $main::BBOLD . $1 if $1;
#		my $char = $2;
#		$self->{after} = $3 . $main::EBOLD if $3;
#		if ($char =~ /[ivx]/) {
#			@charList = (
#				'i',  'ii',  'iii',  'iv',  'v',  'vi',  'vii',  'viii',  'ix',  'x',
#				'xi', 'xii', 'xiii', 'xiv', 'xv', 'xvi', 'xvii', 'xviii', 'xix', 'xx'
#			);
#		} elsif ($char =~ /[IVX]/) {
#			@charList = (
#				'I',  'II',  'III',  'IV',  'V',  'VI',  'VII',  'VIII',  'IX',  'X',
#				'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII', 'XIX', 'XX'
#			);
#		} elsif ($char =~ /[a-z]/) {
#			@charList = ('a' .. 'z');
#		} elsif ($char =~ /\d/) {
#			@charList = (1 .. 20);
#		} else {
#			@charList = ('A' .. 'Z');
#		}
#	} else {
#		@charList = ('A' .. 'Z');
#	}
#	$self->{labels} = [ @charList[ 0 .. $#{ $self->{choices} } ] ];
#	$self->{data}[0] = join(', ', $self->correct_ans);
#	return;
#}

1;
