# Future comment space.

=head1 NAME

parserIntegral - Create an Integral value object in which there are
are answer boxes for the bounds, integrand, and differential.

=head1 DESCRIPTION

Adds the macros 'SingleIntegral', 'DoubleIntegral', and 'TripleIntegral' for combining
multiple answer boxes into a single integral in which the bounds, integrand, and
differential are checked. Also allows for entering in double and triple integral bounds
in different orders, which must match the order of the differential. The resulting object
can be used like a Value object.

An integral is built from either a hash reference in which the keys are the possible
differentials and each key points to a hash of the integrand and bounds.
The bounds are a nested array of bounds going from the outside integral to the inside.

    $integralHash = {dxdy => { func => 'x^2 + y^2', bounds => [[1, 2], [3, 4]]}};

The integral can also be built from an array reference which lists the function,
bounds, and differential in that order.

    $integralArray = ['x^2 + y^2', [[1, 2], [3, 4]], 'dxdy']

You can also use the hash or nested array to list multiple possible answers.

    $integrals = {
        dxdy => { func => '3xy^2', bounds => [[0, 5], ['4y/5', 4]] },
        dydx => { func => '3xy^2', bounds => [[0, 4], [0, '5x/4']] }
    };
    $integrals = [
        ['3xy^2', [[0, 5], ['4y/5', 4]], 'dxdy'],
        ['3xy^2', [[0, 4], [0, '5x/4']], 'dydx'],
    ];

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

    $singleInt = SingleIntegral(['x^2', [[0, 3]], 'dx']);

Allow constant variables in the bounds. A FTC example:

    # f(t) = int_0^t 2x dx
    Context()->variables->are(
        x  => 'Real',
        t  => 'Real',
        dx => 'Real',
    );
    $singleInt = SingleIntegral(
        { dx => { func => '2x', bounds => [[0, 't']] }},
        constantVars => ['t'],
        label => 'f(t)',
    );

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
    $doubleInt = DoubleIntegral(
        [
            ['x^2 + y^2', [[0, 2], [0, 'sqrt(4-y^2)']], 'dxdy'],
            ['x^2 + y^2', [[0, 2], [0, 'sqrt(4-x^2)']], 'dydx'],
            ['r^3', [[0, 'pi/2'], [0, 2]], 'drdtheta'],
            ['r^3', [[0, 2], [0, 'pi/2']], 'dthetadr'],
        ],
        dAkey => 'drdtheta', # Set initial answer key (otherwise based on random hash order)
    );

TripleIntegral Example (bounds can be entered in any order):

    $tripleInt = TripleIntegral(
        { func => '7x + 8y + 9z', bounds => [[1, 2], [3, 4], [5, 6]] },
        swapBounds => 1
    );

=head1 OPTIONS

The following list of options, option => value, can be added after the integral hash/array.

    dAkey         => key,       The integral hash key used as the initial correct answer.
                                Displayed correct answer will change to match student's differential.
                                Default is the last integral found when looping through hash.

    showWarnings  => {0, 1},    Print warnings when checking student's answer.
                                This includes both checking if an integral is valid
                                and which is the first incorrect answer part.
                                Default is the value of $showPartialCorrectAnswers.

    partialCredit => {0, 1},    Give partial credit for each correct answer box.
                                Default is the value of $showPartialCorrectAnswers.

    swapBounds    => {0, 1},    Generate all permutations of the integral bounds and
                                differential if the bounds only contain constants.
                                For single inegrals allow reversing the bounds.
                                Default is 0.

    constantVars  => [array],   An array of variables which can be treated as constants,
                                which can be used in the bounds and integrand.
                                Default is [] (empty).

    size          => percent,   The percent size of the integral symbol and parenthesis
                                around the integrand in HTML ans_rule output.
                                Default is 150.

    label         => TeX,       An optional TeX label that is put before the output of
                                the integral in the ans_rule output.
                                Default is '' (no label).

    labelSize     => percent,   The percent size of the label.
                                Default is 100.

    labelPreview  => {0, 1},    Include the label in the answer preview. Default: 0

    strict        => {0, 1},    Should the integral parser error out if bounds
                                include invalid variables.
                                Default: 1


=name1 TODO - WISHLIST

showWarnings and partialCredit should really be be cmp options and
not object options. But this at least works.

Add a parser that could work with MathQuill so students have to enter
the integral into MathQuill. The string output matches what MathQuill
would produce in an ideal case (nothing multiplied on the outside of
of integrals, and not adding integrals together).

=cut

BEGIN { strict->import; }

sub _parserIntegral_init { }

sub SingleIntegral { parser::Integral->new(1, @_) }
sub DoubleIntegral { parser::Integral->new(2, @_) }
sub TripleIntegral { parser::Integral->new(3, @_) }

package parser::Integral;
our @ISA = ('Value');

our $answerPrefix = 'InTeGrAl_';

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = Value::isContext($_[0]) ? shift : main::Context();
	my ($num, $ints) = @_;
	my %integrals = ();
	my $dAkey     = '';

	$self = bless {
		context       => $context,
		isValue       => 1,
		num           => $num,
		integrals     => {},
		dAkey         => '',
		showWarnings  => $main::showPartialCorrectAnswers,
		partialCredit => $main::showPartialCorrectAnswers,
		size          => 150,
		swapBounds    => 0,
		constantVars  => [],
		label         => '',
		labelSize     => 100,
		labelPreivew  => 0,
		strict        => 1,
		@_
	}, $class;

	my %options = $self->intOpts;
	# Build integrals depending on ints type.
	if (ref($ints) eq 'HASH') {
		foreach (keys %$ints) {
			$dAkey                = $_ =~ s/ //gr;
			$ints->{$dAkey}{diff} = $_;
			$integrals{$dAkey}    = integralHash->new($ints->{$dAkey}, %options);
		}
	} elsif (ref($ints) eq 'ARRAY') {
		if (ref($ints->[0]) eq 'ARRAY') {
			$dAkey = $ints->[0][2] =~ s/ //gr;
			foreach (@$ints) {
				my $dA = $_->[2] =~ s/ //gr;
				$integrals{$dA} = integralHash->new($_, %options);
			}
		} else {
			$dAkey = $ints->[2] =~ s/ //gr;
			$integrals{$dAkey} = integralHash->new($ints, %options);
		}
	} else {
		Value::Error('Input must be a HASH or an ARRAY.');
	}
	$self->{integrals} = \%integrals;
	$self->{dAkey} =~ s/ //g;    # Remove spaces from user provided key.
	$self->{dAkey} = $dAkey unless $self->{dAkey};

	return $self;
}

# Options to pass to integralHashes.
sub intOpts {
	my ($self) = @_;
	return map { $_ => $self->{$_} } ('constantVars', 'label', 'type', 'strict');
}

# Note this doesn't test if bounds can be swapped.
# Leave it up to problem author to use this appropriately.
sub swapBounds {
	my ($self, $s_int) = @_;
	my $ints = $self->{integrals};
	my $num  = $self->{num} - 1;
	return 0 unless ($self->{swapBounds});

	# For single integrals allow reversing of bounds.
	if ($num == 0) {
		if (defined($ints->{ $s_int->{diff}->string })) {
			my $int     = $ints->{ $self->{dAkey} };
			my @bounds  = @{ $int->{bounds} };
			my @sbounds = @{ $s_int->{bounds} };
			if ($bounds[0][0] == $sbounds[0][1] && $bounds[0][1] == $sbounds[0][0]) {
				$int->{bounds} = $s_int->{bounds};
				$int->{func}   = main::Compute('-(' . $int->{func}->string . ')')->reduce('-(-x)' => 1);
			}
			return 1;
		}
		return 0;
	}

	# Swap integral order for multiple integrals.
	my @dA    = split('\*', $s_int->{diff}->string);
	my $dAnew = join('', @dA);
	my $int   = $ints->{ $self->{dAkey} };
	my @dAkey = split('\*', $int->{diff});
	return 0 unless (join('', main::lex_sort(@dA)) eq join('', main::lex_sort(@dAkey)));
	my %order  = map { $dAkey[$_] => $num - $_ } 0 .. $num;
	my @bounds = map { $int->{bounds}[ $order{$_} ] } reverse(@dA);
	$ints->{$dAnew} = integralHash->new([ $int->{func}, \@bounds, $dAnew ], $self->intOpts);
	return 1;
}

# Build answer evaluator.
sub cmp {
	my ($self) = @_;
	my $ans = new AnswerEvaluator;

	$ans->ans_hash(
		type                     => $self->type,
		correct_ans              => $self->string,
		correct_ans_latex_string => $self->TeX,
		correct_value            => $self,
		@_,
	);

	$ans->install_pre_filter('erase');    # Remove blank filter.
	$ans->install_pre_filter(sub { my $ans = shift; (shift)->cmp_preprocess($ans) }, $self);
	$ans->install_evaluator(sub { my $ans  = shift; (shift)->cmp_int($ans) }, $self);
	return $ans;
}

# Get student answers and build student integral.
sub cmp_preprocess {
	my ($self, $ans) = @_;
	my $num     = $self->{num};
	my $context = $self->{context};
	my $inputs  = $main::inputs_ref;
	my $blanks  = 0;
	my $blank   = Value::makeValue('', context => $context);
	my $dAkey   = $self->{integrals}{ $self->{dAkey} }->{diff};
	my @errors  = ();
	$ans->{_filter_name} = 'Build Integral';
	$ans->{cmp_class}    = $self->type;

	# Determine if previewing answer.
	$ans->{isPreview} = $inputs->{previewAnswers} || (($inputs->{action} // '') =~ m/^Preview/);

	# Get ARRAY of responses.
	# Unsure how to deal with badly formatted student input data when trying to make
	# a Value object, so using the diff formula evaluate function for this task.
	my (@answers, @raw);
	foreach (0 .. 2 * $num + 1) {
		my $input = '';
		if (defined($inputs->{ $self->ANS_NAME($_) })) {
			$input = $inputs->{ $self->ANS_NAME($_) };
		}
		$blanks++ if ($input eq '');
		push(@raw, $input);
		my $tmpAns = '';
		if ($input ne '') {
			$tmpAns = $dAkey->cmp(
				showDomainErrors => 0,
				showTypeWarnings => 1,
				showEqualErrors  => 0
			)->evaluate($input);
		}

		# Use a blank answer to still build student's integral if there is an error.
		if ($tmpAns ne '' && ref($tmpAns) eq 'AnswerHash') {
			if ($tmpAns->{ans_message}) {
				push(@errors,  $tmpAns->{ans_message});
				push(@answers, $blank->copy);
			} else {
				push(@answers, main::Formula($input));
			}
		} else {
			push(@errors,  'Answer box ' . ($_ + 1) . ' is blank.');
			push(@answers, $blank->copy);
		}
	}
	my $isBlank  = ($blanks > 0);
	my $bounds   = [ map { [ shift(@answers), shift(@answers) ] } 1 .. $num ];
	my $func     = shift(@answers);
	my $diff     = shift(@answers);
	my $integral = integralHash->new([ $func, $bounds, $diff ], $self->intOpts, strict => 0);
	push(@errors, @{ $integral->{errors} });

	$ans->{isBlank}              = $isBlank;
	$ans->{errors}               = \@errors;
	$ans->{student_value}        = $integral;
	$ans->{original_student_ans} = $isBlank ? '' : join(' ; ', @raw);
	$ans->{student_ans}          = $isBlank ? '' : $integral->string;
	$ans->{preview_text_string}  = $isBlank ? '' : $ans->{student_ans};
	$ans->{preview_latex_string} =
		$isBlank ? '' : ($self->{labelPreview} && $self->{label} ? $self->{label} . '=' : '') . $integral->TeX;
	return $ans;
}

# Check integral
sub cmp_int {
	my ($self, $ans) = @_;
	my $s_int     = $ans->{student_value};
	my $errors    = $ans->{errors};
	my $num       = $self->{num};
	my $integrals = $self->{integrals};
	my $score     = 0;
	$ans->{_filter_name} = 'Check Integral';

	# Stop if previewing answer.
	return $ans if $ans->{isPreview} || $ans->{isBlank};

	# Find integral based off of student's differential
	my $s_dA = $s_int->{diff}->string =~ s/\*//gr;
	if ($s_int->{diffOk} && (defined($integrals->{$s_dA}) || $self->swapBounds($s_int))) {
		$self->swapBounds($s_int) if ($num == 1);    # Force possible bound swap of single integrals.
		$score++;
	} else {
		push(@$errors, "The differential $s_dA is invalid for this integral.");
		$s_dA = $self->{dAkey};
	}
	my $c_int = $integrals->{$s_dA};
	$ans->{correct_ans_latex_string} = $c_int->TeX;

	# Check bounds. Work from inside out.
	foreach (reverse(0 .. $num - 1)) {
		my ($lb1, $ub1) = @{ $c_int->{bounds}[$_] };
		my ($lb2, $ub2) = @{ $s_int->{bounds}[$_] };
		if ($lb1 == $lb2) {
			$score++;
		} else {
			push(@$errors, sprintf('The %s bounds are not correct.', $c_int->boundString($_)));
		}
		if ($ub1 == $ub2) {
			$score++;
		} else {
			push(@$errors, sprintf('The %s bounds are not correct.', $c_int->boundString($_)));
		}
	}

	# Check Integrand.
	if ($c_int->{func} == $s_int->{func}) {
		$score++;
	} else {
		push(@$errors, 'The integrand is not correct.');
	}

	# Compute score.
	# Max score is 75% if any errors fails.
	$score /= 2 * ($num + 1);
	$score = main::min(0.75, $score) if (@$errors);
	$ans->{score} = $self->{partialCredit} ? $score : ($score == 1) ? 1 : 0;

	# Only show the first error found.
	$ans->{ans_message} = shift(@$errors) if $self->{showWarnings};
	return $ans;
}

sub printIntegral {
	my ($self) = @_;
	my $num    = $self->{num} - 1;
	my $size   = $self->{size};
	my $label  = $self->{label} || '';
	my $out    = '';
	my $i      = 0;

	# Create answer rules for bounds, integrand, and differential.
	my (@lb, @ub);
	foreach (0 .. $num) {
		$lb[$_] = $self->mk_ans_rule($i++);
		$ub[$_] = $self->mk_ans_rule($i++);
	}
	my ($func, $diff) = ($self->mk_ans_rule($i++), $self->mk_ans_rule($i++));

	# Deal with TeX and non HTML display modes first.
	if ($main::displayMode eq 'TeX') {
		$out = "\\(\\displaystyle $label = ";
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
            \\(\\displaystyle $label = \\)
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
          <div  style="position: relative; right: 15px;">$lb[$_]</div>
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
	my ($self) = @_;
	my $dA = $self->{dAkey};
	return $self->printTeX($self->{integrals}{$dA});
}

sub printTeX {
	my ($self, $integral) = @_;
	return $integral->TeX;
}

sub string {
	my ($self) = @_;
	my $dA = $self->{dAkey};
	return $self->printString($self->{integrals}{$dA});
}

sub printString {
	my ($self, $integral) = @_;
	return $integral->string;
}

sub ANS_NAME {
	my ($self, $i) = @_;
	return $self->{answerNames}{$i} if defined($self->{answerNames}{$i});
	$self->{answerNames}{0}  = main::NEW_ANS_NAME() unless defined($self->{answerNames}{0});
	$self->{answerNames}{$i} = $answerPrefix . $self->{answerNames}{0} . '_' . $i unless $i == 0;
	return $self->{answerNames}{$i};
}

sub mk_ans_rule {
	my ($self, $i, $size) = @_;
	my $name = $self->ANS_NAME($i);
	$size = 1 unless $size;

	if ($i == 0) {
		my $label = main::generate_aria_label($answerPrefix . $name . '_0');
		return main::NAMED_ANS_RULE($name, $size, aria_label => $label);
	}
	return main::NAMED_ANS_RULE_EXTENSION($name, $size, answer_group_name => $self->{answerNames}{0});
}

sub type {
	my ($self) = @_;
	my $num    = $self->{num};
	my $name   = ($num < 4) ? ('Single', 'Double', 'Triple')[ $num - 1 ] : "$num-";
	return $name . 'Integral';
}

sub ans_rule  { shift->printIntegral }
sub ans_array { shift->printIntegral }

=head1 NAME

integralHash - A hash that represents an integral. This just separates the
integral object into its own thing independent of the full parser which
deals with multiple possible integral objects.

=head1 DESCRIPTION

This is a hash with a few methods to both check and create an integral:
This just separates the hash from the parser::Integral object, which
deals with multiple of these hashes for each key and the students answer.

    bounds =>     An array of [lower, upper] bounds for each integral.

    func   =>     The integrand function.

    diff   =>     The differential.

All objects in the hash are MathObjects.

=cut

package integralHash;

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = Value::isContext($_[0]) ? shift : main::Context();
	my $int     = shift;

	$self = bless {
		context      => $context,
		isValue      => 1,
		constantVars => [],
		label        => '',
		bounds       => [],
		diff         => '',
		func         => '',
		errors       => [],
		strict       => 1,
		@_,
	}, $class;

	# Convert ARRAY to HASH if even number of elements.
	$int = {%$int} if (ref($int) eq 'ARRAY' && scalar(@$int) % 2 == 0);
	# Build integral from input. [func, bounds, diff]
	if (ref($int) eq 'ARRAY') {
		$self->{func}   = $int->[0];
		$self->{bounds} = $int->[1];
		$self->{diff}   = $int->[2];
	} elsif (ref($int) eq 'HASH') {
		$self->{bounds} = $int->{bounds};
		$self->{func}   = $int->{func};
		$self->{diff}   = $int->{diff};
	} else {
		Value::Error('Integral must be defined using a HASH or ARRAY.');
	}
	$self->mkValue;
	return $self if (@{ $self->{errors} });
	$self->checkIntegral;
	return $self;
}

# Convert integral parts to Formula objects.
# Use Formula's as they give nicer output of constants like pi.
sub mkValue {
	my ($self) = @_;
	my $num    = $self->num;
	my $errors = $self->{errors};

	push(@$errors, 'Missing differential.<br>')  unless (defined($self->{diff}));
	$self->{diff} = main::Formula($self->{diff}) unless (Value::isValue($self->{diff}));
	push(@$errors, 'Missing integrand.<br>')     unless (defined($self->{func}));
	$self->{func} = main::Formula($self->{func}) unless (Value::isValue($self->{func}));
	foreach (0 .. $num - 1) {
		my ($lb, $ub) = @{ $self->{bounds}[$_] };
		push(@$errors, sprintf('Missing %s bounds.<br>', $self->boundString($_))) unless (defined($lb) && defined($ub));
		$self->{bounds}[$_][0] = main::Formula($lb) unless (Value::isValue($lb));
		$self->{bounds}[$_][1] = main::Formula($ub) unless (Value::isValue($ub));
	}
	Value::Error(join('<br>', @$errors)) if ($self->{strict} && @$errors);
}

# Check differential, bounds, and integrand use appropriate variables.
sub checkIntegral {
	my ($self)    = @_;
	my $num       = $self->num;
	my $errors    = $self->{errors};
	my $context   = $self->{context};
	my @variables = $context->variables->variables;
	my @constants = @{ $self->{constantVars} };
	my $diff      = $self->{diff}->string;
	my @vars      = split('\*', $diff);

	# Remove approved constants from variable list.
	my %constHash = map { $_ => 1 } @constants;
	@variables = grep { !$constHash{$_} } @variables;

	# Test differential and extract integration variables and order.
	push(@$errors, sprintf('Differential must be a product of %s variables', $num)) if (scalar(@vars) != $num);
	foreach (0 .. $num - 1) {
		last if (@$errors);
		my $dx = $vars[$_];
		push(@$errors, sprintf('Differential variable %s must start with "d".', $dx)) unless ($dx =~ /^d/);
		$dx =~ s/^d//;
		push(@$errors, sprintf('Variable %s used in differential is undefined in this context.', $dx))
			unless (grep(/^$dx$/, @variables));
		$vars[$_] = $dx;
	}
	$self->{diffOk} = 1 unless (@$errors);

	# Test bounds to ensure they use appropriate variables.
	my @allow_vars = @constants;
	foreach (0 .. $num - 1) {
		last if (@$errors);
		push(@$errors, sprintf('The %s bounds can only use %s.', $self->boundString($_), $self->varMsg(@allow_vars)))
			unless ($self->testVars($self->{bounds}[$_][0], @allow_vars)
				&& $self->testVars($self->{bounds}[$_][1], @allow_vars));
		push(@allow_vars, $vars[ $num - 1 - $_ ]);
	}

	# Test integrand function to ensure it uses appropriate variables.
	push(@$errors, sprintf('Integrand can only use %s.', $self->varMsg(@allow_vars)))
		unless ($self->testVars($self->{func}, @allow_vars));

	Value::Error(join('<br>', @$errors)) if ($self->{strict} && @$errors);
}

# Nicely format variable list message.
sub varMsg {
	my ($self, @vars) = @_;
	my $size = scalar(@vars);
	return 'constants'                           if ($size == 0);
	return "the variable $vars[0]"               if ($size == 1);
	return "the variables $vars[0] and $vars[1]" if ($size == 2);
	return 'the variables ' . join(', ', @vars) =~ s/, ([^,]*)$/, and $1/r;
}

# Test if formula only uses listed variables.
sub testVars {
	my ($self, $item, @vars) = @_;
	return 1 unless (Value::isFormula($item));
	my $used = 0;
	foreach (@vars) { $used++ if ($item->usesOneOf($_)); }
	return (scalar(%{ $item->{variables} }) == $used);
}

# Nicely format which integral.
sub boundString {
	my ($self, $this) = @_;
	my $num = $self->num;
	return ''                                  if $num == 1;
	return ('outer', 'inner')[$this]           if $num == 2;
	return ('outer', 'middle', 'inner')[$this] if $num == 3;
	return Value->NameForNumber($this + 1);
}

sub TeX {
	my ($self) = @_;
	my $out = '';

	foreach (@{ $self->{bounds} }) { $out .= '\int_{' . $_->[0]->TeX . '}^{' . $_->[1]->TeX . '} '; }
	return "$out \\left(" . $self->{func}->TeX . '\right)\, ' . $self->{diff}->TeX;
}

sub string {
	my ($self) = @_;
	my $out = '';

	foreach (@{ $self->{bounds} }) { $out .= 'int(' . $_->[0]->string . ', ' . $_->[1]->string . ') '; }
	return "$out (" . $self->{func}->string . ') ' . $self->{diff}->string;
}

sub num { scalar(@{ shift->{bounds} }) }

