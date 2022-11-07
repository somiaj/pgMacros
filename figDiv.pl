
=head1 NAME

figDiv is a function which outputs a figure for the given image (or other object).

=head2 DESCRIPTION

Create a figure div in HTML or framed box in TeX with an optional caption.

    figDiv(image, options);

The image can be any valid image object that is passed to the &image function.

=head2 OPTIONS

The options are a list of 'option => value'. The possible options,
and their default values, are:

  caption          => 'Image'       The caption for the figure.
                                    Set to '' for no caption.

  caption_loc      => 'top'         The location of the caption. Can be set
                                    to either 'top' or 'bottom'.

  width            => 0             The width of the image. If set to 0,
                                    no width is set, and the full image
                                    size is used.
                                    
  height           => 0             The height of the image. If set to 0,
                                    no height is set, and the image height
                                    is used. Note, it is best to only set
                                    the width value, and let the height be
                                    computed automatically based on the
                                    aspect ratio.

  extra_html_tags  => ''            Extra html tags passed to &image function.

  tex_size         => 500           The size of the image in TeX output as a
                                    ratio of the full width, 500 = half the width,
                                    1000 = full width.

  div_width        => 0             The width of the figure div. If set to 0,
                                    width is based off of image.

  div_heght        => 0             The height of the figure div. If set to 0,
                                    height is based off of image.

  isImage          => 1             Pass the input to the &image. Set to 0 to
                                    use the figure div for some other object.

=cut

sub figDiv {
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
	my $caption     = $options{caption};
	my $loc         = $options{caption_loc};
	my %img_options = (
		tex_size        => 950,
		alt             => $options{alt},
		extra_html_tags => $options{extra_html_tags},
	);
	$img_options{width}  = $options{width}  if ($options{width});
	$img_options{height} = $options{height} if ($options{height});

	my $figimg = ($options{isImage}) ? &image($img, %img_options) : $img;
	if ($displayMode eq 'TeX') {
		my $size = $options{tex_size} * 0.001;
		$caption = "{\\bf $caption}";
		$out .= "\\fbox{\\begin{minipage}{$size\\linewidth}\\centering\n";
		$out .= "$caption \\\\\n" if ($loc =~ /^top$/i);
		$out .= "$figimg \\\\\n";
		$out .= "$caption \\\\\n" if ($loc =~ /^bottom$/i);
		$out .= "\\end{minipage}}\n";
	} elsif ($displayMode =~ /^HTML/) {
		my $fig_class = "figure $options{fig_class} $options{fig_class_extra}";
		my $cap_class = "figure-caption $options{cap_class}";
		my $div_style = '';
		if ($options{div_height} || $options{div_width}) {
			$div_style = 'style="';
			$div_style .= "height: $options{div_height}px;" if ($options{div_height});
			$div_style .= "width: $options{div_width}px;"   if ($options{div_width});
			$div_style .= '" ';
		}
		$figimg =~ s/image-view-elt/image-view-elt d-block mx-auto figure-img img-fuild/;
		$caption = " <strong>$caption</strong> ";
		$out .= '<figure class="' . $fig_class . '">';
		$out .= '<figcaption class="' . $cap_class . '">' . $caption . '</figcaption>' if ($loc =~ /^top$/i);
		$out .= '<div ' . $div_style . 'class="m-2">' . $figimg . '</div>';
		$out .= '<figcaption class="' . $cap_class . '">' . $caption . '</figcaption>' if ($loc =~ /^bottom$/i);
		$out .= '</figure>';
	} else {
		$out = "Error: figDiv: Unknown displayMode: $displayMode.\n";
		warn $out;
	}
	return $out;
}
