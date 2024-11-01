
=head1 NAME

parfracChecker.pl - Checkers to determine if a Formula is expanded
into its partial fractions decomposition or if the correct partial
fraction form is entered using unknown constants A, B, C, etc.

=head1 DESCRIPTION

Check if a formula is written in its partial fractions decomposition.

	LoadMacros(qw(PGStandard.pl PGML.pl parfracChecker.pl));
	$f = Formula("3/(x + 1) - 5/(x - 6) + (6x - 1)/(x^2 + 4)");
	$fcmp = $f->cmp(
		bypass_equivalence_test => 1,
		splitFrac               => 1,
		checker                 => $parfracChecker
	);
	BEGIN_PGML
		[_]{$fcmp}
	END_PGML

Check if a formula is written in its partial fractions form.

	Context()->variables->add(map { $_ => 'Real' } A .. F);
	$f = Formula("A/(x+2) + (Bx + C)/(x^2 + 9)");
	$fcmp = $f->cmp(
		bypass_equivalence_test => 1,
		splitFrac               => 1,
		checker                 => $parfracFormChecker
	);

=head2 OPTIONS

	splitFrac => {0, 1}

Split fractions like (Ax + B)/(x^2 + 1)
into Ax/(x^2 + 1) + B/(x^2 + 1).
If this is set to 1, students can enter
answer in either form. If this is set to
zero, the split must match the answer key.
Default: 0

=cut

# Recursive function to split a formula into a list of terms.
# This deals with splitting -(A + B) = -A - B and -(A - B) -A + B.
# if $splitFrac is 1, then this will split apart fractions as well:
# (Ax + B)/C = (Ax)/C + B/C and -(Ax + B)/C = -(Ax)/C - B/C.
sub split_terms {
	my ($mo, $splitFrac) = (@_);
	$splitFrac = 0 unless $splitFrac;
	return ($mo) unless $mo->{tree};

	my $tree = $mo->{tree};
	if ($tree->class eq 'BOP' && $tree->{bop} eq '+') {
		return (
			split_terms(Formula($tree->{lop})->reduce, $splitFrac),
			split_terms(Formula($tree->{rop})->reduce, $splitFrac)
		);
	} elsif ($tree->class eq 'BOP' && $tree->{bop} eq '-') {
		return (
			split_terms(Formula($tree->{lop})->reduce,  $splitFrac),
			split_terms(Formula(Parser::UOP::Neg($tree->{rop}))->reduce, $splitFrac)
		);
	} elsif ($tree->class eq 'UOP'
		&& $tree->{uop} eq 'u-'
		&& $tree->{op}->class eq 'BOP')
	{
		if ($tree->{op}{bop} eq '+') {
			return (
				split_terms(Formula(Parser::UOP::Neg($tree->{op}{lop}))->reduce, $splitFrac),
				split_terms(Formula(Parser::UOP::Neg($tree->{op}{rop}))->reduce, $splitFrac)
			);
		} elsif ($tree->{op}{bop} eq '-') {
			return (
				split_terms(Formula(Parser::UOP::Neg($tree->{op}{lop}))->reduce, $splitFrac),
				split_terms(Formula($tree->{op}{rop})->reduce,  $splitFrac)
			);
		} elsif ($splitFrac && $tree->{op}{bop} eq '/') {
			my @top =
				split_terms(Formula(Parser::UOP::Neg($tree->{op}{lop}))->reduce, $splitFrac);
			my $bot = Formula($tree->{op}{rop})->reduce;
			return map { Formula("($_)/$bot")->reduce } @top;
		}
	} elsif ($splitFrac && $tree->class eq 'BOP' && $tree->{bop} eq '/') {
		my @top = split_terms(Formula($tree->{lop})->reduce, $splitFrac);
		my $bot = Formula($tree->{rop})->reduce;
		return map { Formula("($_)/$bot")->reduce } @top;
	}
	return ($mo);
}

$parfracChecker = sub {
	my ($c, $s, $ans) = @_;
	return 0 if $ans->{isPreview};
	
	Value->Error('Answer is not equivlant to the original fraction.')
		unless $c == $s;

	# Split the answers up:
	my $splitFrac = $ans->{splitFrac} ? 1 : 0;
	my @s_fracs   = split_terms($s->reduce, $splitFrac);
	my @c_fracs   = map { { ans => $_ } } split_terms($c->reduce, $splitFrac);
	my $n_fracs   = scalar(@c_fracs);

	Value->Error('Answer has incorrect number of fractions.')
		unless $n_fracs == scalar(@s_fracs);

	$n_fracs--;
	for my $stu (@s_fracs) {
		for my $i (0 .. $n_fracs) {
			next if $c_fracs[$i]{found};
			if ($c_fracs[$i]{ans} == $stu) {
				$c_fracs[$i]{found} = 1;
				last;
			}
		}
	}

	my $score = 0;
	for (0 .. $n_fracs) { $score++ if $c_fracs[$_]{found}; }
	return 1 if $score == $n_fracs + 1;
	Value->Error('Answer is not written in the correct partial fractions decomposition.');
	return 0;
};

$parfracFormChecker = sub {
	my ($c, $s, $ans) = @_;
	return 0 if $ans->{isPreview};

	my @constants = $ans->{constants} || (A .. F);
	my $c_str = join('', @constants);

	# Check constants are only used once.
	my $s_str = $s->string;
	for (@constants) { $s_str =~ s/$_//; }
	Value->Error('Unknown constants can only be used once in the partial fractions form.')
		if $s_str =~ /[$c_str]/;

	# Replace constants with the same random number for checking.
	my $r_num = main::random(1000, 9999);
	my @subst = map { $_ => $r_num } @constants;

	# Split the answers up:
	my $splitFrac = $ans->{splitFrac} ? 1 : 0;
	my @s_fracs   = split_terms($s->reduce, $splitFrac);
	my @c_fracs   = map { { ans => $_ } } split_terms($c->substitute(@subst)->reduce, $splitFrac);
	my $n_fracs   = scalar(@c_fracs);

	# Double check each fraction includes an unknown constant.
	for my $stu (@s_fracs) {
		Value->Error('Each fraction must contain unkown constants.')
			unless $stu->usesOneOf(@constants);
		$stu = $stu->substitute(@subst);
	}

	Value->Error('Answer has incorrect number of fractions.')
		unless $n_fracs == scalar(@s_fracs);

	$n_fracs--;
	for my $stu (@s_fracs) {
		for my $i (0 .. $n_fracs) {
			next if $c_fracs[$i]{found};
			if ($c_fracs[$i]{ans} == $stu) {
				$c_fracs[$i]{found} = 1;
				last;
			}
		}
	}

	my $score = 0;
	for (0 .. $n_fracs) { $score++ if $c_fracs[$_]{found}; }
	return 1 if $score == $n_fracs + 1;
	Value->Error(
		'Your answer is not written in the correct partial fractions form.'
	);
	return 0;
};

