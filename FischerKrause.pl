# Fischer-Krause ordered permutation generator.
# Generates the next larger permutation of a number array.
# Returns empty array for maximum permutation.
sub permute {
	my $self = shift;
	my @in   = @_;
	my $i    = $j = $#in;
	$i-- while $in[ $i - 1 ] > $in[$i];
	return () unless $i;
	$j-- until $in[$j] > $in[ $i - 1 ];
	($in[ $i - 1 ], $in[$j]) = ($in[$j], $in[ $i - 1 ]);
	my @out = reverse splice(@in, $i);
	return (@in, @out);
}

