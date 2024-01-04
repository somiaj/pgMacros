################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2023 The WeBWorK Project, https://github.com/openwebwork
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=name1 NAME

PGgraphmacros.pl - A wrapper between PGgraphmacros.pl methods and PGplot.pl methods.

=name1 DESCRIPTION

This is a collection of wrapper methods and objects to create a PGplot graph object using the
same methods as PGgraphmacros.pl. This allows older problems to upgrade to use Tikz graphs
without having to update the problem. This should hopefully work in most cases, provided the
problem doesn't call the GD image methods directly.

Use PGplot.pl to create graphs. These methods are all deprecated.

Information about the old methods can be found in PGgraphmacros.pl and the deprecated WWPlot objects.

=cut

BEGIN {
	be_strict();
}

loadMacros('PGplot.pl');

sub _PGgraphmacros2_init {
	return;
}

sub init_graph {
	my ($xmin, $ymin, $xmax, $ymax, %options) = @_;
	my @size;
	if (defined($options{'size'})) {
		@size = @{ $options{'size'} };
	} elsif (defined($options{'pixels'})) {
		@size = @{ $options{'pixels'} };
	} else {
		my $defaultSize = $main::envir{onTheFlyImageSize} || 400;
		@size = ($defaultSize, $defaultSize);
	}

	my $plot = PGplot(size => \@size);
	my $axes = $plot->axes;
	$axes->xaxis(min => $xmin, max => $xmax, visible => 0, showgrid => 0);
	$axes->yaxis(min => $ymin, max => $ymax, visible => 0, showgrid => 0);
	if ($options{axes}) {
		$axes->xaxis(visible => 1);
		$axes->xaxis(gd_loc  => $options{axes}->[1]) if $options{axes}->[1];
		$axes->yaxis(visible => 1) unless (defined($options{'plotVerticalAxis'}) && $options{'plotVerticalAxis'} == 0);
		$axes->yaxis(gd_loc  => $options{axes}->[0]) if $options{axes}->[0];
	}

	# Set grid / ticks
	my ($xdiv, $ydiv);
	if (defined($options{grid})) {
		$xdiv = (${ $options{'grid'} }[0]) ? ${ $options{'grid'} }[0] : 8;
		$ydiv = (${ $options{'grid'} }[1]) ? ${ $options{'grid'} }[1] : 8;
		$axes->xaxis(showgrid => 1);
		$axes->yaxis(showgrid => 1);
	} elsif ($options{ticks}) {
		$xdiv = ${ $options{ticks} }[0] ? ${ $options{ticks} }[0] : 8;
		$ydiv = ${ $options{ticks} }[1] ? ${ $options{ticks} }[1] : 8;
	}
	if ($xdiv && $ydiv) {
		my ($xminor, $yminor);
		for (5, 4, 3, 2, 1) {
			$xminor = $_ if !$xminor && $xdiv % $_ == 0 && $xdiv / $_ > 2;
			$yminor = $_ if !$yminor && $ydiv % $_ == 0 && $xdiv / $_ > 2;
		}
		$axes->xaxis(major => 1, minor => $xminor - 1, tick_num => $xdiv / $xminor);
		$axes->yaxis(major => 1, minor => $yminor - 1, tick_num => $ydiv / $yminor);
	}

	# Add position for moveTo, lineTo, and arrowTo
	$plot->position(0, 0);
	return $plot;
}

sub init_graph_no_labels { return init_graph(@_); }

sub add_functions { &plot_functions; }

sub plot_functions {
	my $plot = shift;
	unless (ref($plot) eq 'PGplot') {
		warn 'The first argument to plot_functions must be a PGplot graph object.';
		return;
	}
	return $plot->add_function(@_);
}

sub closed_circle {
	my ($x, $y, $color) = @_;
	return new Circle($x, $y, $color, 1);
}

sub open_circle {
	my ($x, $y, $color) = @_;
	return new Circle($x, $y, $color, 0);
}

# Backwards compatibility methods and objects for WWPlot PGgraphobjects

package PGplot;

sub _add_data {
	my ($self, @data_list) = @_;
	for (@data_list) {
		$self->add_data($_) if $_->can('gen_data');
	}
	return;
}

sub fn {
	my $self = shift;
	return $self->_add_data(@_);
}

sub install {
	my $self = shift;
	return $self->_add_data(@_);
}

sub fillRegion {
	my $self = shift;
	return $self->_add_data(@_);
}

sub lb {
	my $self = shift;
	return $self->_add_data(@_);
}

sub stamps {
	my $self = shift;
	return $self->_add_data(@_);
}

sub new_color {
	my $self = shift;
	$self->_add_color(@_);
}

sub im { return; }

sub position {
	my ($self, $x, $y) = @_;
	$self->{position} = [ $x, $y ] if (defined($x) && defined($y));
	return @{ $self->{position} };
}

sub moveTo {
	my ($self, $x, $y) = @_;
	$self->position($x, $y);
	$self->{prevdata} = undef;
	return;
}

sub lineTo {
	my ($self, $x, $y, $color, $w, $d) = @_;
	$w = 1       unless defined($w);
	$d = 'solid' unless defined($d);
	$self->add_dataset([ $self->position ], [ $x, $y ], color => $color, width => $w, linestyle => $d);
	$self->position($x, $y);
	return;
}

sub arrowTo {
	my ($self, $x, $y, $color, $w, $d) = @_;
	$w                = 1       unless defined($w);
	$d                = 'solid' unless defined($d);
	$self->{prevdata} = undef;
	$self->add_dataset(
		[ $self->position ], [ $x, $y ],
		color     => $color,
		width     => $w,
		end_mark  => 'arrow',
		linestyle => $d
	);
	$self->position($x, $y);
	return;
}

sub h_axis {
	my ($self, $y, $color) = @_;
	$self->axes->xaxis(position => $y, color => $color);
	return;
}

sub v_axis {
	my ($self, $x, $color) = @_;
	$self->axes->yaxis(position => $x, color => $color);
	return;
}

# No longer distinguish locations of ticks from grid lines, these both configure the ticks.
sub h_ticks {
	my ($self, $color, @ticks) = @_;
	$self->axes->xaxis(tick_color => $color, ticks => [@ticks]);
	return;
}

sub v_ticks {
	my ($self, $color, @ticks) = @_;
	$self->axes->yaxis(tick_color => $color, ticks => [@ticks]);
	return;
}

sub h_grid {
	my ($self, $color, @ticks) = @_;
	$self->axes->xaxis(grid_color => $color, ticks => [@ticks]);
	return;
}

sub v_grid {
	my ($self, $color, @ticks) = @_;
	$self->axes->yaxis(grid_color => $color, ticks => [@ticks]);
	return;
}

package Label;
our @ISA = qw(PGplot::Data);

sub new {
	my ($self, $x, $y, $label, $color, $h_align, $v_align, $fontsize) = @_;
	my $class = ref($self) || $self;
	my $data  = $class->SUPER::new(name => 'label');
	$data->add($x, $y);
	$data->style(
		label    => $label,
		color    => $color    || 'default_color',
		fontsize => $fontsize || 'medium',
		h_align  => $h_align  || 'center',
		v_align  => $v_align  || 'middle'
	);
	return bless $data, $class;
}

sub font {
	my ($self, $font) = @_;
	$self->style(GD_font => $font);
	return;
}

package Circle;

sub new {
	my ($self, $x, $y, $color, $filled) = @_;
	$color  = 'default_color' unless $color;
	$filled = 0               unless $filled;
	my $data = PGplot::Data->new(name => 'stamp');
	$data->add($x, $y);
	$data->style(color => $color, size => 4, symbol => $filled ? 'closed_circle' : 'open_circle');
	return $data;
}

package Fun;
our @ISA = qw(PGplot::Data);

# Needs to accept (CODE), (CODE, PGplot), (CODE, CODE), and (CODE, CODE, PGplot)
sub new {
	my ($self, $rule, $input1, $input2) = @_;
	return unless ref($rule) eq 'CODE';

	my ($sub_x, $sub_y, $plot);
	if (defined($input1) && ref($input1) eq 'CODE') {
		$sub_x = $rule;
		$sub_y = $input1;
		$plot  = $input2 if (defined($input2) && ref($input2) eq 'PGplot');
	} else {
		$sub_x = sub { return $_[0]; };
		$sub_y = $rule;
		$plot  = $input1 if (defined($input1) && ref($input1) eq 'PGplot');
	}

	my $class = ref($self) || $self;
	my $data  = $class->SUPER::new(name => 'function');
	$data->style(color => 'default_color', width => 1);
	$data->set_function(sub_x => $sub_x, sub_y => $sub_y);
	$plot->add_data($data) if $plot;
	return bless $data, $class;
}

sub domain {
	my ($self, $start, $stop) = @_;
	if (defined($start) && defined($stop)) {
		$self->tstart($start);
		$self->tstop($stop);
		return;
	}
	return [ $self->tstart, $self->tstop ];
}

sub tstart {
	my ($self, $start) = @_;
	if (defined($start)) {
		$self->{function}{min} = $start;
		return;
	}
	return $self->{function}{min};
}

sub tstop {
	my ($self, $stop) = @_;
	if (defined($stop)) {
		$self->{function}{max} = $stop;
		return;
	}
	return $self->{function}{max};
}

sub steps {
	my ($self, $steps) = @_;
	if ($steps) {
		$self->style(steps => $steps);
		return;
	}
	return $self->style('steps');
}

sub color {
	my ($self, $color) = @_;
	if ($color) {
		$self->style(color => $color);
		return;
	}
	return $self->style('color');
}

sub weight {
	my ($self, $weight) = @_;
	if ($weight) {
		$self->style(width => $weight);
		return;
	}
	return $self->style('width');
}

1;
