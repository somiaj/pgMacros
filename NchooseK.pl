# Standalone function from PGchoicemacros.pl
sub NchooseK {
	my ($n, $k) = @_;
	my @array = 0 .. ($n - 1);
	my @out   = ();
	while (@out < $k) {
		push(@out, splice(@array, random(0, $#array, 1), 1));
	}
	@out;
}

