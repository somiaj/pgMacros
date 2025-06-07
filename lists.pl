# Macros to generate both unordered and ordered lists.
sub UL {
        my $out = MODES(
                TeX  => "\\begin{itemize}\n",
                HTML => "<ul>\n",
                PTX  => "<ul>\n",
        );
        for my $item (@_) {
                $out .= MODES(
                        TeX       => "\\item $item\n",
                        HTML      => "<li>$item</li>\n",
                        PTX       => "<li><p>$item</p></li>\n",
                );
                $i++;
        }
        $out .= MODES(
                TeX  => "\\end{itemize}\n",
                HTML => "</ul>\n",
                PTX  => "</ul>\n",
        );
}

sub OL {
        my $out = MODES(
                TeX  => "\\begin{enumerate}\n",
                HTML => "<ol>\n",
                PTX  => "<ol>\n",
        );
        for my $item (@_) {
                $out .= MODES(
                        TeX       => "\\item $item\n",
                        HTML      => "<li>$item</li>\n",
                        PTX       => "<li><p>$item</p></li>\n",
                );
                $i++;
        }
        $out .= MODES(
                TeX  => "\\end{enumerate}\n",
                HTML => "</ol>\n",
                PTX  => "</ol>\n",
        );
}

