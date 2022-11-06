
=head1 NAME

plotly3D.pl - Adds Graph3D, an object for creating 3D parametric curves
and 3D parametric surface plots using the plotly JavaScript library.
https://plotly.com/javascript/

=head1 DESCRIPTION

Loading this macro adds the Graph3D method which creates a 3D graph object.
The graph object can be configured by a list of options of the form "option => value".

    $graph = Graph3D(options);

Use the addCurve method to add a parametric curve to the graph.
The following adds a helix to the graph. xFunc, yFunc, and zFunc
are perl functions which return the x, y, z value of each point
using a single parameter t. tMin and tMax are the minimum and maximum
value of the parameter t, and tCount is the number of points to generate.

    $graph->addCurve(
        xFunc  => sub { cos($_[0]); },
        yFunc  => sub { sin($_[0]); },
        zFunc  => sub { $_[0]; },
        tMin   => 0,
        tMax   => 6*pi,
        tCount => 100,
    );

Use the addSurface method to add a parametric surface to the graph.
The following adds the parabolic surface z = x^2 + y^2. xFunc, yFunc,
and zFunc are perl functions which return the x, y, z value of each
point using two parameters u and v. uMin, uMax, vMin, and vMax are
the minimum and maximum value of the two parameters, and uCount and
vCount are the number of points to generate.

    $graph->addSurface(
        xFunc  => sub { $_[0] },
        yFunc  => sub { $_[1] },
        zFunc  => sub { $_[0]**2 + $_[1]**2 },
        uMin   => -5,
        uMax   => 5,
        uCount => 20,
        vMin   => -5,
        vMax   => 5,
        vCount => 20,
    );

Output the graph in PGML using the Print method.

    [@ $graph->Print @]*

Multiple curves surfaces can be added with the appropriate methods.

=head2 Graph3D OPTIONS

Create a graph object: $graph = Graph3D(option => value):

  height      The height and width of the div containing the graph.
  width

  title       Graph title to print above the graph.

  style       CSS style to style the div containing the graph.

  bgcolor     The background color of the graph.

  image       Image filename to be used in hardcopy TeX output.

  tex_size    Size of image in hardcopy TeX output as scale factor from 0 to 1000.
              1000 is 100%, 500 is 50%, etc.

  tex_border  Put (1) or don't put (0) a border around image in TeX output.

  scene       Add a JavaScript sceen configuration dictonary to the plotly layout.
              Example: scene => 'aspectmode: "manual", aspectratio: {x: 1, y: 1, z: 1},
              xaxis: { range: [0,2] }, yaxis: { range: [0,3] }, zaxis: { range: [1,4] }'
              https://plotly.com/javascript/3d-axes/ for more examples.

=head2 addCurve OPTIONS

Create a parametric curve (x(t), y(t), z(t)) using $graph->addCurve(option => value):

  xFunc       Subroutine that returns the x-coordinate from one input t.

  yFunc       Subroutine that returns the y-coordinate from one input t.

  zFunc       Subroutine that returns the z-coordinate from one input t.

  tMin        The minimum, maximum, values for the t input.
  tMax

  tStep       The step size or number of points generated for the t input.
  tCount      tStep = (tMax - tMin) / tCount unless uStep is defined.
              Default is tCount = 100.

  width       The width of the curve. Default: 5

  autoGen     Automatically generate the points using xFunc, yFunc, zFunc.
              Turn this off (0) to plot data.

  xPoints     A string that is a double array "[[a,b,c,...],[d,e,f,...],...]"
  yPoints     containing the data for the plot. Provide this string to plot fixed
  zPoints     data and turn autoGen off (speeds up plots with fixed data).

  colorscale  The colorscale to use for the surface plot. Some options include
              'BdBu' (default), 'YlOrRd', 'YlGnBu', 'Portland', 'Picnic', 'Jet', 'Hot'
              'Greys', 'Greens', 'Electric', 'Earth', 'Bluered', and 'Blackbody'

  opacity     The opacity of the plot, which is a number from 0 to 1. Default: 1.

=head2 addSurface OPTIONS

Create a parametric surface (x(u,v), y(u,v), z(u,v)) using $graph->addSurface(option => value):

  xFunc       Subroutine that returns the x-coordinate from two inputs u and v.

  yFunc       Subroutine that returns the y-coordinate from two inputs u and v.

  zFunc       Subroutine that returns the z-coordinate from two inputs u and v.

  uMin        The minimum, maximum, values for the u input.
  uMax

  uStep       The step size or number of points generated for the u input.
  uCount      uStep = (uMax - uMin) / uCount unless uStep is defined.
              Default is uCount = 20.

  vMin        The minimum, maximum, and step values for the v input.
  vMax

  vStep       The step size or number of points generated for the v input.
  vCount      vStep = (vMax - vMin) / vCount unless vStep is defined.
              Default is uCount = 20.

  autoGen     Automatically generate the points using xFunc, yFunc, zFunc.
              Turn this off (0) to plot data.

  xPoints     A string that is a double array "[[a,b,c,...],[d,e,f,...],...]"
  yPoints     containing the data for the plot. Provide this string to plot fixed
  zPoints     data and turn autoGen off (speeds up plots with fixed data).

  colorscale  The colorscale to use for the surface plot. Some options include
              'BdBu' (default), 'YlOrRd', 'YlGnBu', 'Portland', 'Picnic', 'Jet', 'Hot'
              'Greys', 'Greens', 'Electric', 'Earth', 'Bluered', and 'Blackbody'

  opacity     The opacity of the plot, which is a number from 0 to 1. Default: 1.

=cut

sub _plotly3D_init {
	ADD_JS_FILE('https://cdn.plot.ly/plotly-latest.min.js', 1);
	PG_restricted_eval("sub Graph3D {new plotly3D(\@_)}");
}

our $plotlyCount = 0;

package plotly3D;

sub new {
	my $self  = shift;
	my $class = ref($self) || $self;

	$plotlyCount++;
	$self = bless {
		id         => $plotlyCount,
		plots      => [],
		width      => 500,
		height     => 500,
		title      => '',
		bgcolor    => '#f5f5f5',
		style      => 'border: solid 2px; display: inline-block; margin: 5px; text-align: center;',
		scene      => '',
		image      => '',
		tex_size   => 500,
		tex_border => 1,
		@_,
	}, $class;

	return $self;
}

sub addSurface { push(@{ shift->{plots} }, plotly3D::Surface->new(@_)); }
sub addCurve   { push(@{ shift->{plots} }, plotly3D::Curve->new(@_)); }

sub TeX {
	my $self = shift;
	my $size = $self->{tex_size} * 0.001;
	my $out  = ($self->{tex_border}) ? '\fbox{' : '\mbox{';
	$out .= "\\begin{minipage}{$size\\linewidth}\\centering\n";
	$out .= ($self->{title}) ? "{\\bf $self->{title}} \\\\\n" : '';
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
	my $scene = ($self->{scene}) ? "scene: { $self->{scene} }," : '';

	foreach (@{ $self->{plots} }) {
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
	$scene
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
	my $self  = shift;
	my $class = ref($self) || $self;

	$self = bless {
		uMin       => -5,
		uMax       => 5,
		uStep      => 0,
		uCount     => 20,
		vMin       => -5,
		vMax       => 5,
		vStep      => 0,
		vCount     => 20,
		xFunc      => sub { $_[0] },
		yFunc      => sub { $_[1] },
		zFunc      => sub { $_[0]**2 + $_[1]**2 },
		autoGen    => 1,
		xPoints    => '',
		yPoints    => '',
		zPoints    => '',
		colorscale => 'RdBu',
		opacity    => 1,
		@_,
	}, $class;
	$self->{uStep} = ($self->{uMax} - $self->{uMin}) / $self->{uCount} unless $self->{uStep};
	$self->{vStep} = ($self->{vMax} - $self->{vMin}) / $self->{vCount} unless $self->{vStep};
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
	my $scale = ($self->{colorscale} =~ /^\[/) ? $self->{colorscale} : "'$self->{colorscale}'";

	return <<END_OUTPUT;
var plotlyData${id}_$count = {
	x: $self->{xPoints},
	y: $self->{yPoints},
	z: $self->{zPoints},
	type: 'surface',
	opacity: $self->{opacity},
	colorscale: $scale,
	showscale: false,
};
END_OUTPUT
}

# plotly3D curve plots
package plotly3D::Curve;

sub new {
	my $self  = shift;
	my $class = ref($self) || $self;

	$self = bless {
		tMin       => 0,
		tMax       => 6 * main::pi,
		tStep      => 0,
		tCount     => 100,
		xFunc      => sub { cos($_[0]) },
		yFunc      => sub { sin($_[0]) },
		zFunc      => sub { $_[0] },
		autoGen    => 1,
		xPoints    => '',
		yPoints    => '',
		zPoints    => '',
		width      => 5,
		colorscale => 'RdBu',
		opacity    => 1,
		@_,
	}, $class;
	$self->{tStep} = ($self->{tMax} - $self->{tMin}) / $self->{tCount} unless $self->{tStep};
	$self->buildArray if $self->{autoGen};

	return $self;
}

sub buildArray {
	my $self = shift;
	my $xPts = '';
	my $yPts = '';
	my $zPts = '';
	my $t;

	for ($t = $self->{tMin}; $t <= $self->{tMax}; $t += $self->{tStep}) {
		$xPts .= $self->{xFunc}($t) . ',';
		$yPts .= $self->{yFunc}($t) . ',';
		$zPts .= $self->{zFunc}($t) . ',';
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
	my $scale = ($self->{colorscale} =~ /^\[/) ? $self->{colorscale} : "'$self->{colorscale}'";

	return <<END_OUTPUT;
var plotlyData${id}_$count = {
	x: $self->{xPoints},
	y: $self->{yPoints},
	z: $self->{zPoints},
	type: 'scatter3d',
	mode: 'lines',
	opacity: $self->{opacity},
	line: {
		width: $self->{width},
		color: $self->{zPoints},
		colorscale: $scale,
	},
};
END_OUTPUT
}

