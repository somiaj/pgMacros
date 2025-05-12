# matrix2array($rows, $vars)
# $rows is an array reference of coefficients of each equation or a Value::Matrix.
# $vars is list reference of variables for the coefficients
sub matrix2array {
	my ($in_r, $vars, $hline) = @_;
	my @rows  = (ref($in_r) =~ /Matrix$/) ? $in_r->value : @$in_r;
	my $nvars = 0;
	my @A     = ();
	my @As    = ();

	$hline = -1 unless defined($hline);
	# Figure out some variables if none were provided:
	if (defined($vars)) {
		$nvars = scalar(@$vars);
	} else {
		$nvars = scalar(@{ $rows[0] }) - 1;
		if ($nvars < 5) {
			$vars = [ ('x', 'y', 'z', 'w')[ 0 .. $nvars - 1 ] ];
		} else {
			$vars = [ map {"x_{$_}"} (1 .. $nvars) ];
		}
	}

	# Loop through the rows to setup the array:
	my @arrayRows = ();
	for my $n (0 .. $#rows) {
		my $row    = $rows[$n];
		my $first  = 0;
		my $rowstr = '';
		foreach (0 .. $nvars) {
			my $val = $row->[$_];
			my $var = $vars->[$_];
			if ($_ == $first) {
				if ($_ == $nvars - 1 || ($val ne '' && $val ne '0')) {
					$rowstr .= fmtVal($val, $var);
					next;
				}
				$first++;
				$rowstr .= '&&';
				next;
			}
			if ($_ == $nvars) {
				$rowstr .= '&=&' . $val;
			} elsif ($val ne '' && $val ne '0') {
				$rowstr .= ($val =~ s/^\-//) ? '&-&' : '&+&';
				$rowstr .= fmtVal($val, $var);
			} else {
				$rowstr .= '&&';
			}
		}
		$rowstr .= $n == $hline ? '\\\\\\hline' : '\\\\';
		push @arrayRows, $rowstr;
	}
	return '\begin{array}{' . ('rc' x $nvars) . 'r}' . join('', @arrayRows) . '\end{array}';
}

sub fmtVal {
	my ($val, $var) = @_;
	return $val unless (defined($var) && $var ne '');
	return 0 if ($val eq '0');
	$val = ''  if ($val eq '1');
	$val = '-' if ($val eq '-1');
	return $val . $var;
}
