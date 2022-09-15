$isoChecker = sub {
	my ($correct, $student, $ansHash, $value) = @_;
	my $labels  = $ansHash->{labels};
	my $valid   = $ansHash->{valid} || [0,1];
	my $adjMat  = $ansHash->{adjmat};
	my $stuN    = scalar(@$student); # Number of items in student's answer
	my $score   = 0; # Number of correct items in list
	my $err     = 0; # Error catch

	# Update answer preview to include set brackets
	$ansHash->{preview_latex_string} = '\Big\lbrace ' . $ansHash->{preview_latex_string} . '\Big\rbrace';
	$ansHash->{correct_ans_latex_string} = '\Big\lbrace ' . $ansHash->{correct_ans_latex_string} . '\Big\rbrace';

	# Check if preview, then return
	if ($ansHash->{isPreview}) { return $score; }

	# Main loop to check all points.
	my $n      = scalar @{$labels[0]};
	my %dom    = ();
	my %cdom   = ();
	my %dCheck = ();
	my %cCheck = ();
	my $domI   = 0;
	my $cdomI  = 0;
	my @phi    = ();
	foreach $i (0..$stuN-1) {
		my $p = $student->[$i];

		# Check if item is a point
		unless ($p->type eq 'Point' && $p->value == 2) {
			$err = 1;
			last;
		}
		my ($a, $b) = $p->value;
		
		# Figure out domain/codomain from first point:
		if ($i == 0) {
			foreach $j (0..$#labels) {
			    my $str = join('|', @{$labels[$j]});
			    $domI   = $j if $a =~ /^($str)/;
			    $cdomI  = $j if $b =~ /^($str)/;
			}
		}
		%dom  = map { $labels[$domI][$_-1] => $_ } (1..$n);
		%cdom = map { $labels[$cdomI][$_-1] => $_ } (1..$n);

		if ($dom{$a} && $cdom{$b}) {
			$dCheck{$a}++;
			$cCheck{$b}++;
			$phi[$dom{$a}-1] = $cdom{$b}-1;
			next;
		}
		$err = 3 unless ($cdom{$b});
		$err = 2 unless ($dom{$a});
		last;
	}
	# If $err, then they didn't enter in a set of points.
	Value->Error('Your answer must be a list of ordered pairs, (a,b).') if ($err == 1);
	Value->Error('Your inputs include a value not in the correct domain.') if ($err == 2);
	Value->Error('Your outputs include a value not in the correct codomain.') if ($err == 3);

	# Check if this is a bijective function
	Value->Error('Your answer is not a bijective function.')
		unless (scalar(keys %dCheck) == $n && scalar(keys %cCheck) == $n && $stuN == $n);

	# Check that function uses a valid domain/codomain.
	return 0 unless (($domI == $valid->[0] && $cdomI == $valid->[1]) ||
			($domI == $valid->[1] && $cdomI == $valid->[0]));

	# Check if this is an isomorphism by creating a new adjacency matrix
	# using student supplied function and comparing to original adjacency matrix.
	my @newMat = ();
	foreach my $i (0..$n-1) {
		foreach my $j (0..$n-1) {
			$newMat[$phi[$i]][$phi[$j]] = $adjMat->[$i]->[$j];
		}
	}
	my $str1 = join('', map { join('', @$_) } @newMat);
	my $str2 = join('', map { join('', @$_) } @$adjMat);
	return $n if ($str1 eq $str2);
	return 0;
};

1;
