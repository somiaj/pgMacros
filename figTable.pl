# Uses &image to place an image inside a <figure> with caption.
# If isImage is set to 0, pace the input inside the <figure> instead.
sub figTable {
	my $img = shift;
	my $out = '';

	# standard options
	my %options = (
		tex_size        => 500,
		alt             => '',
		caption         => 'Image',
		caption_loc     => 'top',
		isImage         => 1,
		height          => 0,
		width           => 0,
		div_height      => 0,
		div_width       => 0,
		fig_class       => 'border border-2 border-dark',
		fig_class_extra => 'm-2',
		cap_class       => 'text-dark text-center border-bottom border-dark p-2',
		extra_html_tags => '',
		@_
	);

	$options{alt} = $options{caption} unless $options{alt};
	my $caption   = $options{caption};
	my $loc       = $options{caption_loc};
	my $html_tags = $options{extra_html_tags};
	my %img_options = (
		tex_size        => 950,
		alt             => $options{alt},
		extra_html_tags => $html_tags,
	);
	$img_options{width} = $options{width} if ($options{width});
	$img_options{height} = $options{height} if ($options{height});

	my $figimg = ($options{isImage}) ? &image($img, %img_options) : $img;
	if ($displayMode eq 'TeX') {
		my $size  = $options{tex_size}*0.001;
		$caption  = "{\\bf $caption}";
		$out     .= "\\fbox{\\begin{minipage}{$size\\linewidth}\\centering\n";
		$out     .= "$caption \\\\\n" if ($loc =~ /^top$/i);
		$out     .= "$figimg \\\\\n";
		$out     .= "$caption \\\\\n" if ($loc =~ /^bottom$/i);
		$out     .= "\\end{minipage}}\n"
	} elsif ($displayMode =~ /^HTML/) {
		my $fig_class = "figure $options{fig_class} $options{fig_class_extra}";
		my $cap_class = "figure-caption $options{cap_class}";
		my $div_style = '';
		if ($options{div_height} || $options{div_width}) {
			$div_style = 'style="';
			$div_style .= "height: $options{div_height}px;" if ($options{div_height});
			$div_style .= "width: $options{div_width}px;" if ($options{div_width});
			$div_style .= '" ';
		}
		$figimg  =~ s/image-view-elt/image-view-elt d-block mx-auto figure-img img-fuild/;
		$caption = " <strong>$caption</strong> ";
		$out    .= '<figure class="' . $fig_class . '">';
		$out    .= '<figcaption class="' . $cap_class . '">' . $caption . '</figcaption>' if ($loc =~ /^top$/i);
		$out    .= '<div ' . $div_style . 'class="m-2">' . $figimg . '</div>';
		$out    .= '<figcaption class="' . $cap_class . '">' . $caption . '</figcaption>' if ($loc =~ /^bottom$/i);
		$out    .= '</figure>';
	} else {
		$out = "Error: figTable: Unknown displayMode: $displayMode.\n";
		warn $out;
	}
	return $out;
}
