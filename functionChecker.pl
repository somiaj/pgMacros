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

functionChecker.pl - A list checker to determine if a List of points represents a function, injective function, surjective function, or bijective function from two finite sets of real numbers.

=head1 DESCRIPTION

Check if a list is a function:

	LoadMacros('PGML.pl', 'functionChecker.pl');
	Context('Interval');
	$setA = Set(1,2,3,4,5);
	$setB = Set(1,2,3,4,5);
	Context('Point');
	$fset = List("(1,5), (2,5), (3,3), (4,1), (5,1)");
	$fcmp = $fset->cmp(
		list_checker    => $funcChecker,
		domain          => $setA,
		codomain        => $setB,
		showLengthHints => 0,
	);
	BEGIN_PGML
		[``\Big\lbrace``] [_]{$fcmp} [``\Big\rbrace``]
	END_PGML

Check if a list is an injective function:

	LoadMacros('PGML.pl', 'functionChecker.pl');
	Context('Interval');
	$setA = Set(1,2,3,4,5);
	$setB = Set(1,2,3,4,5);
	Context('Point');
	$fset = List("(1,5), (2,4), (3,3), (4,2), (5,1)");
	$fcmp = $fset->cmp(
		list_checker    => $funcChecker,
		domain          => $setA,
		codomain        => $setB,
		showLengthHints => 0,
		isInjective  => 1,
	);
	BEGIN_PGML
		[``\Big\lbrace``] [_]{$fcmp} [``\Big\rbrace``]
	END_PGML

=head1 OPTIONS

	hideWarings => {0,1}   Hide warning messages.
				Default: 0

	isInjective => {0,1}   Check if the function is injective.
				Default: 0

	isSurjective => {0,1}  Check if the function is surjective.
				Default: 0

	isBijective => {0,1}   Check if the function is bijective.
				Default: 0

	setProduct => 'string' The name of the Cartesian product
				in the warnings if elements in list
				are not in the Cartesian product.
				Default: '\(A\times B\)'

	partialCredit => {0,1} Award partial credit for having some
				valid points in the list.
				Default: 1

	isIncreasing => {0,1}  Check if the function is increasing.
				Default: 0

	isDecreasing => {0,1}  Check if the function is decreasing.
				Default: 0

	isStrict => {0,1}      Make Increasing/Decreasing check strictly.
				Default: 0

=cut

$funcChecker = sub {
	my ($correct, $student, $ansHash, $value) = @_;
	my $domain   = $ansHash->{domain};
	my $codomain = $ansHash->{codomain};
	if ($domain->type ne 'Set' || $codomain->type ne 'Set') {
		Value->Error('Domain and codomain must be finite set of real numbers.');
	}
	my $hideWarnings = $ansHash->{hideWarnings} || 0;
	my $setProduct   = $ansHash->{setProduct}   || '\(A\times B\)';
	my $isInjective  = $ansHash->{isInjective}  || 0;
	my $isSurjective = $ansHash->{isSurjective} || 0;
	my $isIncreasing = $ansHash->{isIncreasing} || 0;
	my $isDecreasing = $ansHash->{isDecreasing} || 0;
	my $isStrict     = $ansHash->{isStrict}     || 0;

	if ($ansHash->{isBijective}) {
		$isInjective  = 1;
		$isSurjective = 1;
	}
	my $nCorrect      = scalar($domain->value);    # Number of correct points in list
	my $n             = scalar(@$student);         # Number of items in student's answer
	my $score         = 0;                         # Number of correct items in list
	my @errors        = ();                        # Waring message list
	my %domainCheck   = ();                        # Hash to check full domain is used
	my %codomainCheck = ();                        # Hash to check if full codomain is used

	# Update answer preview to include set brackets
	$ansHash->{preview_latex_string}     = '\Big\lbrace ' . $ansHash->{preview_latex_string} . '\Big\rbrace';
	$ansHash->{correct_ans_latex_string} = '\Big\lbrace ' . $ansHash->{correct_ans_latex_string} . '\Big\rbrace';

	# Check if preview, then return
	if ($ansHash->{isPreview}) { return ($score, @errors); }

	# Main loop to check all points.
	for (my $i = 0; $i < $n; $i++) {
		my $ith = Value::List->NameForNumber($i + 1);
		my $p   = $student->[$i];

		# Check if item is a point
		if ($p->type ne 'Point' || $p->value != 2) {
			push(@errors, "Your $ith entry is not an element of $setProduct.");
			next;
		}

		# Check if point is in the domain
		my ($a, $b) = $p->value;
		my $inDomain   = $domain->contains("{$a}");
		my $inCodomain = $codomain->contains("{$b}");
		$domainCheck{$a}++ if ($inDomain);
		$codomainCheck{$b}++ if ($inDomain && $inCodomain);
		push(@errors, "Your $ith entry is not an element of $setProduct.") unless ($inDomain && $inCodomain);
	}

	# Is this set a function?
	my $isFunction = (scalar @errors == 0) ? 1 : 0;
	my $dupCheck   = 0;
	foreach my $key (keys %domainCheck) {
		if ($domainCheck{$key} > 1) {
			$dupCheck   = 1;
			$isFunction = 0;
		} else {
			$score++;
		}
	}
	push(@errors, 'Your function used an entry in the domain more than once.') if ($dupCheck);
	unless (keys %domainCheck == $nCorrect) {
		$isFunction = 0;
		push(@errors, "Your function doesn't use all the elements of the domain.");
	}

	# Check if function is injective
	if ($isInjective) {
		my $dupCheck = 0;
		foreach my $key (keys %codomainCheck) {
			if ($codomainCheck{$key} > 1) {
				$dupCheck = 1;
				$score -= ($codomainCheck{$key} - 1);
			}
		}
		push(@errors, 'Your function used an entry in the codomain more than once.') if ($dupCheck);
	}

	# Check if function is surjective
	if ($isSurjective && keys %codomainCheck != scalar($codomain->value)) {
		push(@errors, "Your function doesn't use all the elements of the codomain.");
		my $unique = keys %codomainCheck;
		$score = $unique if ($score > $unique);
	}

	# No partial credit if checking for injective/surjective/bijective
	# functions and the list isn't a valid function.
	$score = 0 if (!$isFunction && ($isInjective || $isSurjective));

	# Check if increasing or decreasing.
	if ($isFunction && ($isIncreasing || $isDecreasing)) {
		my $check  = 1;
		my $strict = ($isStrict) ? ' strictly' : '';
		for (my $i = 1; $i < $n; $i++) {
			my ($x1, $y1) = $student->[$i]->value;
			for (my $j = 0; $j < $i; $j++) {
				my ($x2, $y2) = $student->[$j]->value;
				if (
					$isIncreasing
					&& (($x1 < $x2 && $y1 > $y2)
						|| ($x2 < $x1 && $y2 > $y1)
						|| ($isStrict && $y1 == $y2))
					)
				{
					$score = 0;
					$check = 0;
					push(@errors, "This function is not$strict increasing.");
				}
				if (
					$isDecreasing
					&& (($x1 < $x2 && $y1 < $y2)
						|| ($x2 < $x1 && $y2 < $y1)
						|| ($isStrict && $y1 == $y2))
					)
				{
					$score = 0;
					$check = 0;
					push(@errors, "This function is not$strict decreasing.");
				}
				last unless ($check);
			}
			last unless ($check);
		}
	}

	undef @errors if ($hideWarnings);
	return ($score, @errors);
};

