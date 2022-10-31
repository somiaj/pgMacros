=head1 plotly3D.pl

Adds Graph3D, an object for creating 3D parametric surface plots
using the plotly JavaScript library. https://plotly.com/javascript/

=head2 Examples

Plot the cone z = sqrt(x^2 + y^2) using rectangular coordinates.

  $graph = Graph3D(zFunc => sub { sqrt($_[0]**2 + $_[1]**2) });

Print the HTML and JavaScript to a problem in PGML.

  [@ $graph->Print @]*

Change the default domain of the plot.

  $graph = Graph3D(
    zFunc => sub { sqrt($_[0]**2 + $_[1]**2) },
    uMin  => -10,
    uMax  => 10,
    uStep => 0.5,
    vMin  => -10,
    vMax  => 10,
    vStep => 0.5,
  );

Plot the cone z = sqrt(x^2 + y^2) using polar coordinates.

  $graph = Graph3D(
    xFunc => sub { $_[0]*cos($_[1]) },
    yFunc => sub { $_[0]*sin($_[1]) },
    zFunc => sub { $_[0] },
    uMin  => 0,
    uMax  => 5,
    vMin  => 0,
    vMax  => 2*pi + 0.1,
  );

=head2 Options

Create a parametric surface (x(u,v), y(u,v), z(u,v)) using Graph3D(option => value):

  xFunc       Subroutine that returns the x-coordinate from two inputs u and v.

  yFunc       Subroutine that returns the y-coordinate from two inputs u and v.

  zFunc       Subroutine that returns the z-coordinate from two inputs u and v.

  uMin        The minimum, maximum, and step values for the u input.
  uMax
  uStep

  vMin        The minimum, maximum, and step values for the v input.
  vMax
  vStep

  height      The height and width of the div containing the graph.
  width

  title       Graph title to print above the graph.

  style       CSS style to style the div containing the graph.

  bgcolor     The background color of the graph.

  image       Image filename to be used in hardcopy TeX output.

  tex_size    Size of image in hardcopy TeX output as scale factor from 0 to 1000.
              1000 is 100%, 500 is 50%, etc.

  tex_border  Put (1) or don't put (0) a border around image in TeX output.

  autoGen     Automatically generate the points using xFunc, yFunc, zFunc.
              Turn this off (0) to plot data.

  xPoints     A string that is a double array "[[a,b,c,...],[d,e,f,...],...]"
  yPoints     containing the data for the plot. Provide this string to plot fixed
  zPoints     data and turn autoGen off (speeds up plots with fixed data).

=cut

sub _plotly3D_init {
	ADD_JS_FILE('https://cdn.plot.ly/plotly-latest.min.js', 1);
	PG_restricted_eval("sub Graph3D {new plotly3D(\@_)}");
}

our $plotlyCount = 0;
package plotly3D;

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;

	$plotlyCount++;
	$self = bless {
		id         => $plotlyCount,
		plots      => [],
		width      => 500,
		height     => 500,
		title      => '',
		bgcolor    => '#f5f5f5',
		style      => 'border: solid 2px; display: inline-block; margin: 5px; text-align: center;',
		image      => '',
		tex_size   => 500,
		tex_border => 1,
		@_,
	}, $class;

	return $self;
}

sub addSurface { push(@{shift->{plots}}, plotly3D::Surface->new(@_)); }

sub TeX {
	my $self  = shift;
	my $size  = $self->{tex_size}*0.001;
	my $out   = ($self->{tex_border}) ? '\fbox{' : '\mbox{';
	$out      .= "\\begin{minipage}{$size\\linewidth}\\centering\n";
	$out      .= ($self->{title}) ? "{\\bf $self->{title}} \\\\\n" : '';
	if ($self->{image}) {
		$out .= &main::image($self->{image}, tex_size => 950);
	} else {
		$out .= '3D image not avaialble. You must view it online.';
	}
	$out .= "\n\\end{minipage}}\n";

	return $out;
}

sub HTML {
	my $self  = shift;
	my $id    = $self->{id};
	my $width = $self->{width} + 5;
	my $title = ($self->{title}) ? "<strong>$self->{title}</strong>" : '';
	my $plots = '';
	my @data  = ();
	my $count = 0;

	foreach (@{$self->{plots}}) {
		$count++;
		$plots .= $_->HTML($id, $count);
		push(@data, "plotlyData${id}_$count");
	}
	my $dataout = '[' . join(', ', @data) . ']';

	return <<END_OUTPUT;
<div style="width: ${width}px; $self->{style}">
$title
<div id="plotlyDiv$id" style="width: $self->{width}px; height: $self->{height}px;"></div>
</div>
<script>
$plots
var plotlyLayout$id = {
	autosize: true,
	showlegend: false,
	paper_bgcolor: "$self->{bgcolor}",
	margin: {
		l: 5,
		r: 5,
		b: 5,
		t: 5,
	}
};
Plotly.newPlot('plotlyDiv$id', $dataout, plotlyLayout$id);
</script>
END_OUTPUT

	return $out;
}

sub Print {
	my $self = shift;
	my $out  = '';

	$self->buildArray if ($self->{autoGen});
	if ($main::displayMode =~ /HTML/) {
		$out = $self->HTML;
	} elsif ($main::displayMode eq 'TeX') {
		$out = $self->TeX;
	} else {
		$out = "Unsupported display mode.";
	}
	return $out;
}

# plotly3D surface plots
package plotly3D::Surface;

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;

	$self = bless {
		uMin       => -5,
		uMax       => 5,
		uStep      => 0.1,
		vMin       => -5,
		vMax       => 5,
		vStep      => 0.1,
		xFunc      => sub { $_[0] },
		yFunc      => sub { $_[1] },
		zFunc      => sub { $_[0]**2 + $_[1]**2 },
		autoGen    => 1,
		xPoints    => '',
		yPoints    => '',
		zPoints    => '',
		colorscale => 'RdBu',
		@_,
	}, $class;
	$self->buildArray if $self->{autoGen};

	return $self;
}

sub buildArray {
	my $self = shift;
	my $xPts = '';
	my $yPts = '';
	my $zPts = '';
	my ($u, $v);

	for ($u = $self->{uMin}; $u <= $self->{uMax}; $u += $self->{uStep}) {
		my @xTmp = ();
		my @yTmp = ();
		my @zTmp = ();
		for ($v = $self->{vMin}; $v <= $self->{vMax}; $v += $self->{vStep}) {
			push @xTmp, $self->{xFunc}($u, $v);
			push @yTmp, $self->{yFunc}($u, $v);
			push @zTmp, $self->{zFunc}($u, $v);
		}
		$xPts .= '[' . join(',', @xTmp) . '],';
		$yPts .= '[' . join(',', @yTmp) . '],';
		$zPts .= '[' . join(',', @zTmp) . '],';
	}
	chop $xPts;
	chop $yPts;
	chop $zPts;
	$self->{xPoints} = "[$xPts]";
	$self->{yPoints} = "[$yPts]";
	$self->{zPoints} = "[$zPts]";
}

sub HTML {
	my $self  = shift;
	my $id    = shift || 1;
	my $count = shift || 1;
	return <<END_OUTPUT;
var plotlyData${id}_$count = {
	x: $self->{xPoints},
	y: $self->{yPoints},
	z: $self->{zPoints},
	type: 'surface',
	colorscale: '$self->{colorscale}',
	showscale: false,
};
END_OUTPUT
}

