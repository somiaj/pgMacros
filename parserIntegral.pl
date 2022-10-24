# Future comment space.

=head1 NAME

parserIntegral - A parserMultiAnswer.pl wapper for creating integrals in which there
are answer boxes for the bounds, integrand, and differential.

=head1 DESCRIPTION

Adds the macros 'SingleIntegral', 'DoubleIntegral', and 'TripleIntegral' for combining
multiple answer boxes into a single integral in which the bounds, integrand, and
differential are checked. Also allows for entering in double and triple integral bounds
in different orders, which must match the order of the differential. The resulting object
can be used like a Value object.

An integral is built from a hash reference in which the keys are the possible
differentials and each key points to a hash of the integrand and bounds.
The bounds are a nested array of bounds going from the outside integral to the inside.

    $integralHash = {dxdy => { func => 'x^2 + y^2', bounds => [[1, 2], [3,4]]}};

Before creating an integral, be sure to add all variables to the current context.
This is not done automatically and you will get errors if using undefined variables.:

    Context()->variables->are(
        x  => 'Real',
        y  => 'Real',
        z  => 'Real',
        dx => 'Real',
        dy => 'Real',
        dz => 'Real',
    );

=head1 EXAMPLES

SingleIntegral Example:

    $singleInt = SingleIntegral({dx => { func => 'x^2', bounds => [[0, 3]] }});

DoubleIntegral Example:

    $doubleInt = DoubleIntegral({
        dxdy => { func => 'x^2 + y^2', bounds => [[0, 4], ['y/2', 2]] },
        dydx => { func => 'x^2 + y^2', bounds => [[0, 2], [0, '2x']] },
    });

Note: That the integrand function is defined for each integral so an integral could
be entered in different coordinate systems.

    Countext()->variables->are(
        x      => 'Real',
        y      => 'Real',
        r      => 'Real',
        theta  => ['Real', TeX => '\theta '],
        dx     => 'Real',
        dy     => 'Real',
        dr     => 'Real',
        dtheta => ['Real', TeX => 'd\theta '],
    );
    $doubleInt = DoubleIntegral({
        dxdy     => { func => 'x^2 + y^2', bounds => [[0, 2], [0, 'sqrt(4-y^2)']] },
        dydx     => { func => 'x^2 + y^2', bounds => [[0, 2], [0, 'sqrt(4-x^2)']] },
        drdtheta => { func => 'r^3', bounds => [[0, 'pi/2'], [0,2]] },
        dthetadr => { func => 'r^3', bounds => [[0, 2], [0, 'pi/2']] },
    });

TripleIntegral Example:

    $tripleInt = TripleIntegral({ func => '7x + 8y + 9z', bounds => [[1, 2], [3, 4], [5, 6]] });

=head1 OPTIONS

The following list of options, option => value, can be added after the integral hash.

    dAkey        => key,       The integral hash key used as the initial correct answer.
                               Displayed correct answer will change to match student's differential.
                               Default is the last integral found when looping through hash.

    showWarnings => {0, 1},    Print warnings when checking student's answer.
                               This includes both checking if an integral is valid
                               and which is the first incorrect answer piece.
                               Default is the value of $showPartialCorrectAnswers.

    swapBounds   => {0, 1},    Generate all permutations of the integral bounds and
                               differential if the bounds only contain constants.
                               Default is 0.

    constantVars => [array],   An array of variables which can be treated as constants,
                               which can be used in the bounds and integrand.
                               Default is [] (empty).

    size         => percent,   The percent size of the integral symbol and parenthesis
                               around the integrand in HTML ans_rule output.
                               Default is 150.

    label        => TeX,       An optional TeX label that is put before the output of
                               the integral TeX and ans_rule output.
                               Default is '' (no label).

    labelSize    => percent,   The percent size of the label.
                               Default is 100.

=name1 TODO - WISHLIST

Remove dependency on parserMultiAnswer.pl.

Add a parser that could work with MathQuill so students have to enter
the integral into MathQuill. The string output matches what MathQuill
would produce in an ideal case (nothing multiplied on the outside of
of integrals, and not adding integrals together).

=cut

sub _parserIntegral_init {
	main::loadMacros('parserMultiAnswer2.pl'); # Use a modified version.
	main::PG_restricted_eval('sub SingleIntegral {parser::Integral->new(1, @_)}');
	main::PG_restricted_eval('sub DoubleIntegral {parser::Integral->new(2, @_)}');
	main::PG_restricted_eval('sub TripleIntegral {parser::Integral->new(3, @_)}');
}

package parser::Integral;
our @ISA = ('Value');

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = Value::isContext($_[0]) ? shift : main::Context();
	my $num     = shift;                                               # Number of integrals
	my $ints    = shift;                                               # HASH of integrals

	$ints = \%$ints if (ref($ints) eq 'ARRAY' && scalar(@$ints) % 2 == 0);    # Convert ARRAY to hash if possible
	Value::Error('Input must be a HASH of integrals') unless (ref($ints) eq 'HASH');

	# Convert everything to Formula's as needed.
	# This prevents type errors if students enter in a formula for a constant bound.
	foreach my $dA (keys %$ints) {
		$ints->{$dA}{diff} = main::Formula($dA);
		Value::Error('Integrand func is not defined for differential %s.', $dA) unless (defined($ints->{$dA}{func}));
		$ints->{$dA}{func} = main::Formula($ints->{$dA}{func}) unless (Value::isFormula($ints->{$dA}{func}));
		foreach (0 .. $num - 1) {
			my ($lb, $ub) = @{ $ints->{$dA}{bounds}[$_] };
			Value::Error('Missing %s bounds for differential %s.', $self->boundString($_))
				unless (defined($lb) && defined($ub));
			$ints->{$dA}{bounds}[$_][0] = main::Formula($lb) unless (Value::isFormula($lb));
			$ints->{$dA}{bounds}[$_][1] = main::Formula($ub) unless (Value::isFormula($ub));
		}
		$dAkey = $dA;    # Answer key is the last integral found
	}

	$self = bless {
		ma            => undef,
		context       => $context,
		isValue       => 1,
		num           => $num,
		integrals     => $ints,
		dAkey         => $dAkey,
		showWarnings  => $main::showPartialCorrectAnswers,
		partialCredit => $main::showPartialCorrectAnswers,
		size          => 150,
		swapBounds    => 0,
		constantVars  => [],
		label         => '',
		labelSize     => 100,
		@_
	}, $class;

	# Check integrals
	foreach (keys %$ints) { $self->checkIntegral($ints->{$_}); }
	# Swap bounds if configured and variables aren't used in bounds.
	$self->swapAllBounds if ($self->{swapBounds} && $num > 1);
	# Create MultiAnswer object.
	$self->makeMultiAnswer;

	return $self;
}

# Check integral integrity.
sub checkIntegral {
	my $self         = shift;
	my $int          = shift;
	my $showWarnings = defined($_[0]) ? shift : 1;
	my $num          = $self->{num};
	my $context      = $self->{context};
	my @variables    = $context->variables->variables;
	my @constants    = @{ $self->{constantVars} };
	my $diff         = $int->{diff}->string;
	my @vars         = split('\*', $diff);
	my $errorMsg     = '';

	# Remove approved constants from variable list.
	my %constHash = map { $_ => 1 } @constants;
	@variables = grep { !$constHash{$_} } @variables;

	# Test differential and extract integration variables and order.
	$errorMsg = sprintf('Differential must be a product of %s variables', $num)
		if (!$errorMsg && scalar(@vars) != $num);
	foreach (0 .. $num - 1) {
		last if ($errorMsg);
		my $dx = $vars[$_];
		$errorMsg = sprintf('Differential variable %s must start with "d".', $dx) if ($dx !~ /^d/);
		$dx =~ s/^d//;
		$errorMsg = sprintf('Variable %s used in differential is undefined in this context.', $dx)
			unless ($errorMsg || /^$dx$/, @variables);
		$vars[$_] = $dx;
	}

	# Test bounds to ensure they use appropriate variables.
	my @allow_vars = @constants;
	foreach (0 .. $num - 1) {
		last if ($errorMsg);
		$errorMsg = sprintf('The %s bounds can only use %s.', $self->boundString($_), $self->varMsg(@allow_vars))
			unless ($self->testVars($int->{bounds}[$_][0], @allow_vars)
				&& $self->testVars($int->{bounds}[$_][1], @allow_vars));
		push(@allow_vars, $vars[ $num - 1 - $_ ]);
	}

	# Test integrand function to ensure it uses appropriate variables.
	$errorMsg = sprintf('Integrand can only use %s.', $self->varMsg(@allow_vars))
		unless ($errorMsg || $self->testVars($int->{func}, @allow_vars));

	return (0, $errorMsg)   if ($errorMsg && $showWarnings == 2);
	Value::Error($errorMsg) if ($errorMsg && $showWarnings);
	return 1;
}

# Nicely format variable list message.
sub varMsg {
	my $self = shift;
	my $size = scalar(@_);
	return 'constants'                     if ($size == 0);
	return "the variable $_[0]"            if ($size == 1);
	return "the variables $_[0] and $_[1]" if ($size == 2);
	return 'the variables ' . join(', ', @_) =~ s/, ([^,]*)$/, and $1/r;
}

# Test if formula only uses listed variables.
sub testVars {
	my $self = shift;
	my $item = shift;
	my @vars = @_;
	my $used = 0;
	foreach (@vars) { $used++ if (Value::isFormula($item) && $item->usesOneOf($_)); }
	return 1 unless (Value::isFormula($item));
	return (scalar(%{ $item->{variables} }) == $used);
}

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

sub swapAllBounds {
	my $self      = shift;
	my $dA        = $self->{dAkey};
	my $ints      = $self->{integrals};
	my $int       = $ints->{$dA};
	my @bounds    = @{ $ints->{$dA}{bounds} };
	my @constants = @{ $self->{constantVars} };
	my @dAs       = split('\*', $int->{diff}->string);
	my $num       = $self->{num} - 1;
	my @list      = (0 .. $num);
	my %rlist     = map { $_ => $num - $_ } @list;

	# If any bounds use non-constant variables, don't swap bounds.
	foreach (@bounds) {
		return unless ($self->testVars($_->[0], @constants) && $self->testVars($_->[1], @constants));
	}

	my $stop = 0;
	until ($stop) {
		@list = $self->permute(@list);
		unless (@list) {    # Final permutation is returned as a blank list to stop loop.
			$stop = 1;
			@list = reverse(0 .. $num);
		}
		my $dAnew = join('', @dAs[@list]);
		next if defined($ints->{$dAnew});
		$ints->{$dAnew}{func}   = $int->{func};
		$ints->{$dAnew}{diff}   = main::Formula($dAnew);
		$ints->{$dAnew}{bounds} = [ map { $bounds[ $rlist{$_} ] } reverse @list ];
	}
}

# Checks if two integrals are the same. Issues warnings if configured.
# First integral should be the correct integral and second the answer.
sub cmpIntegrals {
	my $self     = shift;
	my $int1     = shift;
	my $int2     = shift;
	my $num      = $self->{num};
	my $score    = 0;
	my $errorMsg = '';

	# Check bounds. Work from inside out.
	foreach (reverse(0 .. $num - 1)) {
		my ($lb1, $ub1) = @{ $int1->{bounds}[$_] };
		my ($lb2, $ub2) = @{ $int2->{bounds}[$_] };
		if ($lb1 == $lb2) {
			$score++;
		} else {
			$errorMsg = sprintf('The %s bounds are not correct.', $self->boundString($_)) unless ($errorMsg);
		}
		if ($ub1 == $ub2) {
			$score++;
		} else {
			$errorMsg = sprintf('The %s bounds are not correct.', $self->boundString($_)) unless ($errorMsg);
		}
	}

	# Check Integrand.
	if ($int1->{func} == $int2->{func}) {
		$score++;
	} else {
		$errorMsg = 'The integrand is not correct.' unless ($errorMsg);
	}

	return ($score, $errorMsg);
}

sub makeMultiAnswer {
	my $self      = shift;
	my $dAkey     = $self->{dAkey};
	my $integrals = $self->{integrals};
	my $integral  = $integrals->{$dAkey};
	my $num       = $self->{num};
	my @bounds    = map { @{ $integral->{bounds}->[$_] } } 0 .. $num - 1;

	$self->{ma} = main::MultiAnswer(@bounds, $integral->{func}, $integral->{diff})->with(
		singleResult     => 1,
		allowBlankAnswer => 0,
		checkTypes       => 1,
		format           => 'int(%s, %s) ' x $num . '(%s) %s',
		tex_format       => '\int_{%s}^{%s} ' x $num . '\left(%s\right)\, %s',
		checker          => sub {
			my ($correct, $student, $ma, $ansHash) = @_;

			# Stop if previewing answer.
			return 0 if $ansHash->{isPreview};

			# Alternate variables to simplify coding syntax.
			my @c        = @{$correct};
			my @s        = @{$student};
			my $score    = 0;
			my $errorMsg = '';

			# Find integral based off of student's differential
			my $s_dA = $s[ 2 * $num + 1 ]->string =~ s/\*//gr;
			if (defined($integrals->{$s_dA})) {
				$score++;
			} else {
				$errorMsg = "The differential $s_dA is invalid for this integral.";
				$s_dA     = $dAkey;
			}
			$ansHash->{correct_ans_latex_string} = $self->printTeX($s_dA);

			# Build student integral, compare answer, and compute score.
			my @bounds = ();
			foreach (0 .. $num - 1) { push(@bounds, [ $s[ 2 * $_ ], $s[ 2 * $_ + 1 ] ]); }
			my $sint = { func => $s[ 2 * $num ], bounds => [@bounds], diff => $s[ 2 * $num + 1 ] };
			my ($intCheck, $intMsg) = $self->checkIntegral($sint, 2);
			my ($cmpScore, $cmpMsg) = $self->cmpIntegrals($integrals->{$s_dA}, $sint);
			$score += $cmpScore;
			$score /= 2 * ($num + 1);                                  # Trun score into a percent.
			$score    = main::min(0.75, $score) unless ($intCheck);    # Max score is 75% if checkIntegral fails.
			$errorMsg = ($errorMsg) ? $errorMsg : ($intMsg) ? $intMsg : $cmpMsg;

			if ($self->{partialCredit}) {
				$ma->setMessage(1, $errorMsg) if ($errorMsg && $self->{showWarnings});
				return $score;
			} else {
				Value::Error($errorMsg) if ($errorMsg && $self->{showwarnings});
				return ($score == 1);
			}
		}
	);
}

sub boundString {
	my $self = shift;
	my $this = shift;
	my $num  = $self->{num};
	return ''                                  if $num == 1;
	return ('outer', 'inner')[$this]           if $num == 2;
	return ('outer', 'middle', 'inner')[$this] if $num == 3;
	return Value->NameForNumber($this);
}

sub printIntegral {
	my $self  = shift;
	my $num   = $self->{num} - 1;
	my $size  = $self->{size};
	my $label = $self->{label} || '';
	my $out   = '';

	# Create answer rules from MultiAnswer object.
	my (@lb, @ub);
	foreach (0 .. $num) {
		$lb[$_] = $self->{ma}->ans_rule(1);
		$ub[$_] = $self->{ma}->ans_rule(1);
	}
	my ($func, $diff) = ($self->{ma}->ans_rule(1), $self->{ma}->ans_rule(1));

	# Deal with TeX and non HTML display modes.
	if ($main::displayMode eq 'TeX') {
		$out = "$label \\(\\displaystyle";
		foreach (0 .. $num) {
			$out .= "\\int_{$lb[$_]}^{$ub[$_]}";
		}
		$out .= "\\left($func\\right)\\, $diff\\)";
		return $out;
	}
	return 'Display mode not supported.' unless ($main::displayMode =~ /HTML/);

	my $labelHTML = '';
	if ($label) {
		my $labelSize = $self->{labelSize};
		$labelHTML = <<ENDHTML;
    <div style="grid-row-start: 1; grid-row-end: 2;"></div>
    <div style="grid-row-start: 2; grid-row-end: 3;">
        <div style="display: flex; flex-wrap: nowrap; flex-direction: row; align-items: center; justify-content: center; height: 100%; font-size: $labelSize%;">
            $label
        </div>
    </div>
    <div style="grid-row-start: 3; grid-row-end: 4;"></div>
ENDHTML
	}

	$out = '<div style="display: inline-grid;">' . "\n$labelHTML";
	foreach (0 .. $num) {
		$out .= <<ENDHTML;
    <div style="grid-row-start: 1; grid-row-end: 2;">
        <div style="display: flex; flex-wrap: nowrap; flex-direction: row; align-items: flex-end; justify-content: center; height: 100%; padding: 5px;">
          <div style="position: relative; left: 15px;">$ub[$_]</div>
        </div>
    </div>
    <div style="grid-row-start: 2; grid-row-end: 3;">
        <div style="display: flex; flex-wrap: nowrap; flex-direction: row; align-items: center; justify-content: center; height: 100%; font-size: $size%;">
            \\(\\displaystyle\\int\\)
        </div>
    </div>
    <div style="grid-row-start: 3; grid-row-end: 4;">
        <div style="display: flex; flex-wrap: nowrap; flex-direction: row; align-items: flex-start; justify-content: center; height: 100%; padding: 5px;">
          <div style="position: relative; right: 15px;">$lb[$_]</div>
        </div>
    </div>
ENDHTML
	}
	$out .= <<ENDHTML;
    <div style="grid-row-start: 1; grid-row-end: 2;"></div>
    <div style="grid-row-start: 2; grid-row-end: 3;">
        <div style="display: flex; flex-wrap: nowrap; flex-direction: row; align-items: center; height: 100%">
            <div style="font-size: $size%;">\\(\\Big(\\)</div>
            <div>$func</div>
            <div style="font-size: $size%;">\\(\\Big)\\)</div>
            <div>$diff</div>
        </div>
    </div>
    <div style="grid-row-start: 3; grid-row-end: 4;"></div>
</div>
ENDHTML
	return $out;
}

sub TeX {
	my $self = shift;
	return $self->printTeX($self->{dAkey});
}

sub printTeX {
	my $self     = shift;
	my $dA       = shift;
	my $integral = $self->{integrals}{$dA};
	my $out      = '';

	foreach (@{ $integral->{bounds} }) { $out .= '\int_{' . $_->[0]->TeX . '}^{' . $_->[1]->TeX . '} '; }
	return "$out \\left(" . $integral->{func}->TeX . '\right)\, ' . $integral->{diff}->TeX;
}

sub string {
	my $self = shift;
	return $self->printString($self->{dAkey});
}

sub printString {
	my $self     = shift;
	my $dA       = shift;
	my $integral = $self->{integrals}{$dA};
	my $out      = '';

	foreach (@{ $integral->{bounds} }) { $out .= 'int(' . $_->[0]->string . ', ' . $_->[1]->string . ') '; }
	return "$out (" . $integral->{func}->string . ') ' . $integral->{diff}->string;
}

sub cmp { shift->{ma}->cmp }
sub ans_rule  { shift->printIntegral }
sub ans_array { shift->printIntegral }

