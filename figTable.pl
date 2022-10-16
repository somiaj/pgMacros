# Uses &image to place an image inside a <figure> with caption.
# If isImage is set to 0, pace the input inside the <figure> instead.
sub figTable {
	my $img = shift;
	my $out = '';

	# standard options
	my %options = (
		tex_size    => 500,
		alt         => '',
		caption     => 'Image',
		caption_loc => 'top',
		isImage     => 1,
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
		my $cap_style = 'figure-caption text-dark text-center border-bottom border-dark p-2';
		$figimg  =~ s/image-view-elt/image-view-elt d-block mx-auto figure-img img-fuild/;
		$caption = " <strong>$caption</strong> ";
		$out    .= "<figure class='figure border border-2 border-dark'>";
		$out    .= '<figcaption class="' . $cap_style . '">' . $caption . '</figcaption>' if ($loc =~ /^top$/i);
		$out    .= '<div class="m-2">' . $figimg . '</div>';
		$out    .= '<figcaption class="' . $cap_style . '">' . $caption . '</figcaption>' if ($loc =~ /^bottom$/i);
		$out    .= '</figure>';
	} else {
		$out = "Error: figTable: Unknown displayMode: $displayMode.\n";
		warn $out;
	}
	$out;
}
