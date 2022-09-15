=name DESCRIPTION

Collection of some more useful utility functions too
small to be their own macro.

=cut

sub nth_word {
	my $self = shift;
	my $n    = shift;
	my $uc   = shift;
	if ($n > 19) {
		my $suffix = 'th';
		$suffix = 'st' if ($n % 10 == 1);
		$suffix = 'nd' if ($n % 10 == 2);
		$suffix = 'rd' if ($n % 10 == 3);
		return "$n$suffix";
	}
	my $out = ('zeroth', 'first', 'second', 'third', 'fourth', 'fifth', 'sixth', 'seventh',
		   'eighth', 'ninth', 'tenth', 'eleventh', 'twelfth', 'thirteenth', 'fourteenth',
		   'fifteenth', 'sixteenth', 'seventeenth', 'eighteenth', 'nineteenth')[$n];
	$out = ucfirst($out) if ($uc);
	return $out;
}

sub NchooseK {
	my ($n, $k) = @_;
	my @array   = 0..($n-1);
	my @out     = ();
	while (@out < $k) {
		push(@out, splice(@array, random(0,$#array,1), 1));
	}
	return @out;
}


