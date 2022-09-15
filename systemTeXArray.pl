# matrix2array($rows, $vars)
# $rows is a list reference of coefficients of each equation or a Value::Matrix.
# $vars is list reference of variables for the coefficients
# Be sure to end $vars with '' for no variable for the constant term.
sub matrix2array {
	my $in_r  = shift;
	my $vars  = shift || ['x', 'y', 'z', ''];
	my @rows  = (ref($in_r) =~ /Matrix$/) ? $in_r->value : @$in_r;
	my $nrows = $#rows;
	my $nvars = scalar(@$vars) - 1;
	my @A     = ();
	my @As    = ();

	foreach my $i (0..$nrows) {
		my $first = 0;
		foreach my $j (0..$nvars) {
			my $val = $rows[$i][$j];
			my $var = $vars->[$j];
			if ($j == $first) {
				if ($j == $nvars - 1 || $val != 0 || $val =~ /^\w/) {
					$A[$i][$j] = fmtVal($val, $var);
					next;
				}
				$first++;
				next;
			}
			if ($j == $nvars) {
				$As[$i][$j] = '=';
				$A[$i][$j]  = fmtVal($val, $var);
			} elsif ($val ne '0' || $val =~ /^\w/) {
				$As[$i][$j] = ($val < 0) ? '-' : '+';
				$A[$i][$j]  = fmtVal(($val < 0) ? -$val : $val, $var);
			}
		}
	}
	my $out = '\begin{array}{' . ('rc'x$nvars) . 'r}';
	foreach $i (0..$nrows) {
		$out .= join('&', ($A[$i][0], map { "$As[$i][$_] & $A[$i][$_]" } (1..$nvars))) . '\\\\';
	}
	chop($out); chop($out);
	$out .= '\end{array}';
	return $out;
}
sub fmtVal {
	my ($val, $var) = @_;
	return 0 unless ($val != 0 || $val =~ /^\w/);
	return $val if ($var eq '');
	$val = '' if ($val == 1);
	$val = '-' if ($val == -1);
	return $val . $var;
}
