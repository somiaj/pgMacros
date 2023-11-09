loadMacros('PGtikz.pl', 'NchooseK.pl');

=name

Functions to create random adjacency matrices:

  random_graph($size, $edges);
  random_diagraph($size, $edges);

Returns a random $size X $size adjacency matrix with $edges edges.

=cut

sub random_graph     { randomMatrix(0, @_) }
sub random_digraph   { randomMatrix(1, @_) }
sub random_adjMatrix { randomMatrix(0, @_) }

sub randomMatrix {
	my $directed = shift;
	my $size     = shift;
	my $edges    = shift;
	my $max      = ($directed) ? $size * $size : $size * ($size - 1) / 2;
	$edges = $max if ($edges > $max);
	my @edges  = NchooseK($max, $edges);
	my $edge   = 0;
	my @adjMat = (map { [ (0) x $size ] } 1 .. $size);
	my $stop   = $size - 1;

	foreach my $i (0 .. $stop) {
		$stop = $i - 1 unless ($directed);
		foreach my $j (0 .. $stop) {
			if (grep(/^$edge$/, @edges)) {
				$adjMat[$i][$j] = 1;
				$adjMat[$j][$i] = 1 unless ($directed);
			}
			$edge++;
		}
	}
	return @adjMat;
}

=name

  create_tikz_graph($adjMat, $labels, %options)

Creates a graph from an adjacency matrix using the
provided list of labels. If the labels list is empty,
the nodes are not labeled.

Options are:

  shuffle       Place nodes around circle in random order. Default: 0

  directed      Use arrows for graph edges. Default: 0

  scale         The TiKz image scale. Default: 2

  radius        The radius of the circle the nodes are placed around. Default: 1.5

  node_size     The size of the nodes, in pixels.

  inner_sep     Padding on nodes when labels are on the inside. Default: 0

  label_inside  Place the labels inside the nodes instead on their edges. Default: 0

  label_format  Format the node labels. Default: '\bf\large'

  node_style    TiKz format of the nodes. Can be 'circle' (default) or 'rectangle',
                and include a fill=color option, 'circle,fill=blue'.

  node_loc      An array of 2 (or 3 element) arrays specifying the x and y location of
                every node. The third element is the side, 'above', 'below', 'left',
                or 'right', to bend edges in directed graphs. 

  swap_xy       When using node_loc to set node locations, if set to 1, these will swap
  reverse_x     x and y, or multiply x and/or y by -1. If set to -1 it will randomally
  reverse_y     preform the action.


=cut

sub create_tikz_graph {
	my $adjMat  = shift;
	my $labels  = shift;
	my $size    = scalar(@$adjMat);
	my %options = (
		shuffle      => 0,
		directed     => 0,
		scale        => 2,
		radius       => 1.5,
		rotation     => 90,
		node_size    => 5,
		inner_sep    => 0,
		label_inside => 0,
		label_format => '\bf\large',
		node_style   => 'circle',
		node_loc     => 0,
		swap_xy      => 0,
		reverse_x    => 0,
		reverse_y    => 0,
		@_
	);

	# Set random bits
	foreach ('swap_xy', 'reverse_x', 'reverse_y') {
		$options{$_} = random(0, 1, 1) if ($options{$_} == -1);
	}

	# Create vertices
	my $vertices = '';
	my @order    = ($options{shuffle}) ? NchooseK($size, $size) : (0 .. $size - 1);
	my $edge     = 0;
	my @side     = (map {'below'} 1 .. $size);
	my $nodes    = $options{node_loc};
	foreach my $i (@order) {
		# Allow a position array to be sent
		my $vert_loc = '';
		if (ref($nodes) eq 'ARRAY') {
			my ($x, $y) =
				$options{swap_xy} ? ($nodes->[$edge][1], $nodes->[$edge][0]) : ($nodes->[$edge][0], $nodes->[$edge][1]);
			$side[ $order[$edge] ] = $nodes->[$edge][2] if defined($nodes->[$edge][2]);
			$x                     = -$x                if $options{reverse_x};
			$y                     = -$y                if $options{reverse_y};
			$vert_loc              = "$x,$y";
		} else {
			my $theta = ($edge * floor(360 / $size + 0.5) + $options{rotation}) % 360;
			if ($theta <= 65 || $theta >= 295) {
				$side[$i] = 'right';
			} elsif ($theta > 65 && $theta < 115) {
				$side[$i] = 'above';
			} elsif ($theta >= 115 && $theta <= 245) {
				$side[$i] = 'left';
			}
			$vert_loc = "$theta:$options{radius}";
		}
		$edge++;
		my $label = (defined($labels->[$i])) ? '{' . $options{label_format} . ' ' . $labels->[$i] . '}' : '{}';
		$label = ($options{label_inside}) ? "[] $label" : "[label=$side[$i]:$label]{}";
		$vertices .= " \\vertex ($i) at ($vert_loc) $label;";
	}

	# Create edges
	my $edges = '';
	my $stop  = $size - 1;
	foreach my $i (0 .. $stop) {
		$stop = $i - 1 unless ($options{directed});
		foreach my $j (0 .. $stop) {
			if ($options{directed}) {
				next unless ($adjMat->[$i]->[$j] == 1);
				my $dir = ($i == $j) ? "loop $side[$i]" : 'bend right';
				$edges .= " \\draw[edge] ($i) to[$dir] ($j);";
			} else {
				$edges .= "($i) edge ($j) " if ($adjMat->[$i]->[$j] == 1);
			}
		}
	}
	my $path      = ($options{directed}) ? '' : '\path';
	my $tikz_code = "$vertices $path $edges;";
	my $gr        = createTikZImage();
	$gr->ext('svg');
	$gr->addToPreamble('\newcommand{\vertex}{\node[vertex]}');
	$gr->tikzLibraries('arrows.meta,calc') if ($options{directed});
	my $tikz_opts =
		'scale='
		. $options{scale}
		. ',vertex/.style={'
		. $options{node_style}
		. ',draw,minimum size='
		. $options{node_size}
		. 'pt,inner sep='
		. $options{inner_sep} . 'pt}';
	$tikz_opts .= ',edge/.style={-{Latex[length=3mm, width=2mm]}}' if ($options{directed});
	$gr->tikzOptions($tikz_opts);
	$gr->tex($tikz_code);
	return $gr;
}

# get_edges(adjacency matrix, labels, start string = '}', end string = '}');
# Returns an array of edges as ordered pairs.
sub get_edges {
	my $adjMat = shift;
	my $n      = scalar(@$adjMat) - 1;
	my $labels = shift || [ 0 .. $n ];
	my $start  = shift || '{';
	my $end    = shift || '}';
	my @edges  = ();
	foreach my $i (0 .. $n) {
		foreach $j (0 .. $i) {
			push(@edges, "$start$labels->[$i],$labels->[$j]$end") if ($adjMat->[$i]->[$j] == 1);
		}
	}
	return @edges;
}

# Checks if an adjacency matrix is symmetric
sub check_symmetric {
	my $adjMat = shift;
	my $n      = scalar(@$adjMat);
	my $m      = scalar(@{ $adjMat->[0] });
	my $sym    = 1;
	return 0 unless ($n == $m);
	foreach my $i (1 .. $n - 1) {
		foreach my $j (0 .. $i - 1) {
			$sym = 0 unless ($adjMat->[$i]->[$j] == $adjMat->[$j]->[$i]);
		}
	}
	return $Sym;
}

# Checks if two adjacency matrices are equal
sub check_equal {
	my $mat1 = shift;
	my $mat2 = shift;
	my $n    = $#mat1;
	my $equ  = 1;
	return 0 unless ($n == $#mat2);
	foreach my $i (0 .. $n) {
		foreach my $j (0 .. $n) {
			$equ = 0 unless ($mat1->[$i]->[$j] == $mat2->[$i]->[$j]);
		}
	}
	return $equ;
}

# Turns a string from PGnauGraphCatalog.pl into an adjacency matrix.
sub nau2mat {
	map { [ split(' ', $_) ] } split(';', shift);
}

1;
