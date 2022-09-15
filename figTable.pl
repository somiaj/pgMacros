# Uses &image to place an image inside a <figure> with caption.
# If isImage is set to 0, pace the input inside the <figure> instead.
sub figTable {
	my $img = shift;
	my $out = '';

	# standard options
	my %options = (
		tex_size    => 500,
		alt         => '',
		padding     => 5,
		caption     => 'Image',
		caption_loc => 'top',
		isImage     => 1,
		@_
	);

	$options{alt} = $options{caption} unless $options{alt};
	my $padding   = $options{padding};
	my $caption   = $options{caption};
	my $loc       = $options{caption_loc};
	my $html_tags = $options{extra_html_tags} . 'style="margin:' . $padding . 'px;" class="d-block mx-auto figure-img img-fuild"';
	my %img_options = (
		tex_size        => $options{tex_size},
		alt             => $options{alt},
		extra_html_tags => $html_tags,
	);
	$img_options{width} = $options{width} if ($options{width});
	$img_options{height} = $options{height} if ($options{height});

	my $figimg = ($options{isImage}) ? &image($img, %img_options) : $img;
	if ($displayMode eq 'TeX') {
		my $pad   = $options{padding} - 10;
		$caption  = "{\\bf $caption}";
		$out     .= '{\begin{tabular}{|c|}\hline';
		$out     .= "\n" . $caption . "\\\\\\hline\n" if ($loc =~ /^top$/i);
		$out     .= "\\\\[${pad}pt]\n" . $figimg . "\\\\[$options{padding}pt]\\hline";
		$out     .= "\n" . $caption . "\n\\\\\\hline" if ($loc =~ /^bottom$/i);
		$out     .= '\end{tabular}}';
	} elsif ($displayMode =~ /^HTML/) {
		$figimg  =~ s/image-view-elt/image-view-elt d-block mx-auto figure-img img-fuild/;
		$caption = " <strong>$caption</strong> ";
		$out    .= "<figure class='figure border border-2 border-dark'>";
		$out    .= '<figcaption class="figure-caption text-dark text-center border border-2 p-2">' . $caption . '</figcaption>' if ($loc =~ /^top$/i);
		$out    .= $figimg;
		$out    .= '<figcaption class="figure-caption text-dark text-center border border-2 p-2">' . $caption . '</figcaption>' if ($loc =~ /^bottom$/i);
		$out    .= '</figure>';
	} else {
		$out = "Error: figTable: Unknown displayMode: $displayMode.\n";
		warn $out;
	}
	$out;
}
