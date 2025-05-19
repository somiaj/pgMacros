# Macro to reduce to row echelon form, which returns an
# array of row ops and the resulting matrix each step.
# Each step is an array reference: [TeX Row Op, Perl Matrix Array]
#   @steps = row_echelon_form($matrix, %options)
#
# Options:
#   normalize => 0 or 1      Scale pivots to 1. Default: 0
#   reduced   => 0 or 1      Compute reduced row echelon form. Default: 0

sub row_echelon_form {
	my ($in, %opts) = @_;
	my @A      = ref($in) =~ /Matrix$/ ? $in->value : @$in;
	my $m      = scalar(@A);                                  # number of rows
	my $n      = scalar(@{ $A[0] });                          # number of columns
	my @steps  = ();
	my %pivots = ();
	my $r      = -1;

	for my $j (0 .. $n - 1) {
		my $i = $r + 1;
		while ($i < $m and $A[$i][$j] == 0) {
			$i += 1;
		}
		next if $i == $m;
		$r += 1;

		unshift(@pivots, [ $r, $j ]);

		# Row switch:
		if ($i != $r) {
			@A[ $i, $r ] = @A[ $r, $i ];
			push(@steps, [ step_string($i, $r), m_copy(@A) ]);
		}

		# Row scale:
		if ($opts{normalize} && $A[$r][$j] != 1) {
			my $lambda = $A[$r][$j];
			for (0 .. $n - 1) {
				$A[$r][$_] /= $lambda;
			}
			push(@steps, [ step_string($r, $i, $lambda), m_copy(@A) ]);
		}

		# Row addition:
		for my $k ($r + 1 .. $m - 1) {
			my $alpha = $A[$r][$j];
			my $beta  = -$A[$k][$j];
			next if $beta == 0;

			my $GCD = gcd(abs($alpha), abs($beta));
			$alpha /= $GCD;
			$beta  /= $GCD;

			for my $p (0 .. $n - 1) { $A[$k][$p] = $beta * $A[$r][$p] + $alpha * $A[$k][$p]; }
			push(@steps, [ step_string($r, $k, $alpha, $beta), m_copy(@A) ]);
		}
	}

	# Work backwards to reduced row echelon form.
	if ($opts{reduced}) {
		for $r (reverse(0 .. $m - 1)) {
			my $j = 0;

			# Find pivot.
			for (0 .. $n - 1) {
				last if $A[$r][$j] != 0;
				$j++;
			}
			next if $j == $n;

			# Row addition:
			for my $k (0 .. $r - 1) {
				my $alpha = $A[$r][$j];
				my $beta  = -$A[$k][$j];
				next if $beta == 0;

				my $GCD = gcd(abs($alpha), abs($beta));
				$alpha /= $GCD;
				$beta  /= $GCD;

				for my $p (0 .. $n - 1) { $A[$k][$p] = $beta * $A[$r][$p] + $alpha * $A[$k][$p]; }
				push(@steps, [ step_string($r, $k, $alpha, $beta), m_copy(@A) ]);
			}

			# Scale row if it hasn't been scaled yet.
			if ($A[$r][$j] != 1) {
				my $lambda = $A[$r][$j];
				for (0 .. $n - 1) {
					$A[$r][$_] /= $lambda;
				}
				push(@steps, [ step_string($r, $i, $lambda), m_copy(@A) ]);
			}
		}
	}

	return @steps;
}

sub step_string {
	my ($i, $j, $alpha, $beta) = @_;
	$i += 1;
	$j += 1;
	my $step;

	if ($beta) {
		if ($beta == 1) {
			$beta = '';
		} elsif ($beta == -1) {
			$beta = '-';
		}
		if ($alpha == 1) {
			$alpha = '+';
		} elsif ($alpha == -1) {
			$alpha = '-';
		} elsif ($alpha > 0) {
			$alpha = "+$alpha";
		}
		return "${beta}R_$i ${alpha}R_$j \\rightarrow R_$j";
	}
	if ($alpha) {
		$alpha = $alpha == -1 ? '-' : "\\frac{1}{$alpha}";
		return "${alpha}R_$i \\rightarrow R_$i";
	}
	return "R_$i \\leftrightarrow R_$j";
}

sub m_copy {
	my @A = @_;
	my @B = ();
	for my $row (@A) {
		push(@B, [@$row]);
	}
	return \@B;
}

# format_row_steps
sub format_row_steps {
	my ($A, $steps, %opts) = @_;
	my $tex_str = '\begin{aligned} &' . $A->TeX . ' \\\\ ';
	for (@$steps) {
		my $op = $_->[0];
		my $M  = Matrix($_->[1]);
		$M->split($opts{split}) if $opts{split};
		$tex_str .= "\\overset{$op}{\\longrightarrow}&" . $M->TeX . ' \\\\ ';
	}
	$tex_str .= '\end{aligned}';
	return $tex_str;
}
