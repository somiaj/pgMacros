
=head1 DESCRIPTION

Creates a new AugmentedMatrix context in which matrices can be
drawn with an augment line between the specified column.
The new method split(n) will place an augment line after column n.

  loadMacros('augmentedMatrix.pl');
  Context('AugmentedMatrix');
  $M = Matrix([[1,2,3,4],[5,6,7,8],[9,0,1,2]);
  $M->split(3);

Both the TeX and the ans_array output will have a vertical line
between the third and fourth column. To combine two (or more)
matrices into an augmented matrix use AugmentMatrix:

  $M = AugmentMatrix($M1, $M2);

where $M1 and $M2 are MathObject matrices or perl arrays with the
same number of rows.

=cut

sub _contextAugmentedMatrix_init { context::Augmented::Matrix::Init() }

sub mkArray {
	my $in  = shift;
	my @out = ();
	if (ref($in) =~ /Matrix$/) {
		@out = $in->value;
	} elsif (ref($in) =~ /Vector$/) {
		@out = map { [$_] } $in->value;
	} elsif (ref($in) eq 'ARRAY' && ref(@$in[0]) eq 'ARRAY') {
		@out = map { [@$_] } @$in;
	}
	return @out;
}

sub AugmentMatrix {
	my @A     = mkArray(shift);
	my $rows  = $#A;
	my $split = scalar @{ $A[0] };
	return unless ($rows);
	while (@_) {
		my @B = mkArray(shift);
		next unless (ref($B[0]) eq 'ARRAY' && $rows == $#B);
		map { push @{ $A[$_] }, @{ $B[$_] } } (0 .. $rows);
	}
	my $C = Matrix(@A);
	$C->split($split) if ($C->context->{name} eq 'AugmentedMatrix');
	return $C;
}

package context::Augmented::Matrix;

sub Init {
	my $context = $main::context{AugmentedMatrix} = Parser::Context->getCopy("Matrix");
	$context->{value}{Matrix} = "Value::Augmented::Matrix";
}

# Modifications to add augment line to matrices
package Value::Augmented::Matrix;
our @ISA = ('Value::Matrix');

# Sets and returns the location to split the augmented matrix at.
sub split {
	my $self  = shift;
	my $value = shift;
	return 0                 unless (defined($value) || defined($self->{split_at}));
	return $self->{split_at} unless defined($value);
	my ($rows, $cols) = $self->dimensions;
	return unless ($value >= 0 && $value < $cols);
	$self->{split_at} = $value;
	return;
}

# Override to draw a line in the matrix at the split location.
sub arrayString {
	my $self  = shift;
	my $value = shift;
	my $split = $self->split;
	if ($value =~ /\{array\}\{(c+)\}/) {
		my $orig = $1;
		my $n    = length($orig);
		my $new  = ($split) ? ('c' x $split) . '|' . ('c' x ($n - $split)) : 'c' x $n;
		$value =~ s/\{$orig\}/{$new}/ if ($orig ne $new);
	}
	return $value;
}

sub TeX {
	my $self = shift;
	my $TeX  = $self->SUPER::TeX(@_);
	return $self->arrayString($TeX);
}

# Override for the ans_array and text answer preview to draw the augmented matrix line.
sub format_matrix_HTML {
	my $self    = shift;
	my $array   = shift;
	my %options = (open => '', close => '', sep => '', tth_delims => 0, @_);
	$self->{format_options} = [%options] unless $self->{format_options};
	my ($open, $close, $sep) = ($options{open}, $options{close}, $options{sep});
	my ($rows, $cols) = (scalar(@{$array}), scalar(@{ $array->[0] }));
	my $HTML       = "";
	my $class      = 'class="ans_array_cell"';
	my $cell       = "display:table-cell;vertical-align:middle;";
	my $pad        = "padding:4px 0;";
	my $sepAugment = '';
	my $split      = $self->split;

	if ($sep) {
		$sep        = '<span class="ans_array_sep" style="' . $cell . 'padding:0 2px">' . $sep . '</span>';
		$sepAugment = $sep;
	} else {
		$sep = '<span class="ans_array_sep WTF" style="' . $cell . 'width:8px;"></span>';
		$sepAugment =
			'<span class="ans_array_sep" style="'
			. $cell
			. 'width:12px;background: linear-gradient(#000, #000) no-repeat center/1px 100%;"></span>';
	}
	$sepAugment = '</span>' . $sepAugment . '<span ' . $class . ' style="' . $cell . $pad . '">';
	$sep        = '</span>' . $sep . '<span ' . $class . ' style="' . $cell . $pad . '">';
	if ($options{top_labels}) {
		$HTML .=
			'<span style="display:table-row"><span '
			. $class
			. ' style="'
			. $cell
			. $pad . '">'
			. join($sep, @{ $options{top_labels} })
			. '</span></span>';
	}
	foreach my $i (0 .. $rows - 1) {
		my @list = EVALUATE(@{ $array->[$i] });
		$HTML .= '<span style="display:table-row"><span ' . $class . ' style="' . $cell . $pad . '">' . $list[0];
		foreach (1 .. $#list) {
			$HTML .= ($_ == $split) ? $sepAugment . $list[$_] : $sep . $list[$_];
		}
		$HTML .= '</span></span>';
	}
	$HTML  = '<span class="ans_array_table" style="display:inline-table; vertical-align:middle">' . $HTML . '</span>';
	$open  = $self->format_delimiter($open,  $rows, $options{tth_delims});
	$close = $self->format_delimiter($close, $rows, $options{tth_delims});
	if ($open ne '' || $close ne '') {
		my $delim = "display:inline-block; vertical-align:middle;";
		$HTML =
			'<span class="ans_array_open" style="'
			. $delim
			. ' margin-right:4px">'
			. $open
			. '</span>'
			. $HTML
			. '<span class="ans_array_close" style="'
			. $delim
			. ' margin-left:4px">'
			. $close
			. '</span>';
	}
	return '<span class="ans_array" style="display:inline-block;vertical-align:.5ex"'
		. ($options{ans_last_name}
			? qq{ data-feedback-insert-element="$options{ans_last_name}" data-feedback-insert-method="append_content"}
			: '')
		. '>'
		. $HTML
		. '</span>';
}

sub EVALUATE {
	map { (Value::isFormula($_) && $_->isConstant ? $_->eval : $_) } @_;
}

sub cmp_preprocess {
	my $self = shift;
	my $ans  = shift;
	$self->SUPER::cmp_preprocess($ans);
	$ans->{preview_latex_string} = $self->arrayString($ans->{preview_latex_string});
}

1;
