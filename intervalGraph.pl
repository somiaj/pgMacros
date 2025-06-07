
BEGIN { strict->import }

sub _intervalGraph_init {
	ADD_CSS_FILE('node_modules/jsxgraph/distrib/jsxgraph.css');
	ADD_CSS_FILE('js/GraphTool/graphtool.css');
	ADD_JS_FILE('node_modules/jsxgraph/distrib/jsxgraphcore.js', 0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/graphtool.js',                     0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/pointtool.js',                     0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/linetool.js',                      0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/circletool.js',                    0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/parabolatool.js',                  0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/quadratictool.js',                 0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/cubictool.js',                     0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/intervaltools.js',                 0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/sinewavetool.js',                  0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/triangle.js',                      0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/quadrilateral.js',                 0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/segments.js',                      0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/filltool.js',                      0, { defer => undef });

	return;
}

loadMacros('PGtikz.pl');

our $interval_graph_count = 0;

sub intervalDescription {
	my $interval = shift;
	$interval =~ s/ //g;
	my ($open, $close) = split(',', $interval);
	my @tmp   = split('', $open);
	my $start = join('', @tmp[ 1 .. $#tmp ]);
	$open = $tmp[0];
	@tmp  = split('', $close);
	my $end = join('', @tmp[ 0 .. $#tmp - 1 ]);
	$close = $tmp[-1];

	my ($start_description, $end_description);
	if ($start eq '-inf') {
		$start_description = 'left end of the real number line with an arrow head pointing to the left';
	} else {
		$start_description = "point $start with " . ($open eq '(' ? 'an open' : 'a closed') . ' circle';
	}
	if ($end eq 'inf') {
		$end_description = 'right end of the real number line with an arrow head pointing to the right';
	} else {
		$end_description = "point $end with " . ($close eq ')' ? 'an open' : 'a closed') . ' circle';
	}

	return
		'Graph of a real number line, which is a horiztonal line with arrow heads on both ends. '
		. 'Tick marks are shown and labeled at the points -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, and 5. '
		. "A horiztional line starts at the $start_description and exteneds to the $end_description.";
}

sub intervalGraph {
	my $interval = shift;
	$interval =~ s/ //g;
	my $description = intervalDescription($interval);

	if ($main::displayMode eq 'TeX') {
		my ($open, $close) = split(',', $interval);
		my @tmp   = split('', $open);
		my $start = join('', @tmp[ 1 .. $#tmp ]);
		$open = $tmp[0];
		@tmp  = split('', $close);
		my $end = join('', @tmp[ 0 .. $#tmp - 1 ]);
		$close = $tmp[-1];

		my $left_end      = '';
		my $left_shorten  = '';
		my $right_end     = '';
		my $right_shorten = '';
		if ($start eq '-inf') {
			$left_end = '{ Stealth[scale = 1.1] }';
		} else {
			$left_end     = '{ Circle[scale = 1.1' . ($open eq '(' ? ', open' : '') . '] }';
			$left_shorten = ', shorten < = -8.25pt';
		}
		if ($end eq 'inf') {
			$right_end = '{ Stealth[scale = 1.1] }';
		} else {
			$right_end     = '{ Circle[scale = 1.1' . ($close eq ')' ? ', open' : '') . '] }';
			$right_shorten = ', shorten > = -8.25pt';
		}

		$start = -6 if $start eq '-inf';
		$end   =  6 if $end eq 'inf';
		my $graph = main::createTikZImage();
		$graph->tikzLibraries('arrows.meta');
		$graph->tikzOptions('x=0.4340in,y=1.3021in');
		my $tikz = <<END_TIKZ;
\\tikzset{
	>={Stealth[scale=1.8]},
	clip even odd rule/.code={\\pgfseteorule},
	inverse clip/.style={ clip,insert path=[clip even odd rule]{
		(-6,-0.4) rectangle (6,0.4) }
	}
}
\\definecolor{borderblue}{HTML}{356AA0}
\\definecolor{fillpurple}{HTML}{A384E5}
\\pgfdeclarelayer{background}
\\pgfdeclarelayer{foreground}
\\pgfsetlayers{background,main,foreground}
\\begin{pgfonlayer}{background}
	\\fill[white,rounded corners=14pt]
	(-6,-0.4) rectangle (6,0.4);
\\end{pgfonlayer}
\\huge
\\draw[<->,thick] (-6,0) -- (6,0)
node[above left,outer sep=2pt]{\\(\\)};
\\foreach \\x in {1,2,3,4,5,-1,-2,-3,-4,-5,0}{\\draw[thin] (\\x,9pt) -- (\\x,-9pt) node[below]{\\(\\x\\)};}
\\draw[borderblue,rounded corners=14pt,thick] (-6,-0.4) rectangle (6,0.4);
\\begin{pgfonlayer}{foreground}
\\clip[rounded corners=14pt] (-6,-0.4) rectangle (6,0.4);
\\end{pgfonlayer}
\\begin{pgfonlayer}{background}
\\end{pgfonlayer}\\begin{pgfonlayer}{foreground}
\\clip[rounded corners=14pt] (-6,-0.4) rectangle (6,0.4);
\\draw[thick, blue, line width = 4pt, $left_end-$right_end$left_shorten$right_shorten] ($start, 0) -- ($end, 0);
\\end{pgfonlayer}
\\begin{pgfonlayer}{background}
\\end{pgfonlayer}
END_TIKZ

		$graph->tex($tikz);
		return image($graph, alt => $description);
	}

	$interval =~ s/inf/infinity/g;
	$interval_graph_count++;
	return <<END_HTML;
		<div id="interval_graph_${interval_graph_count}" class="graphtool-solution-container"></div>
		<script>
			(() => {
				const initialize = () => {
					graphTool('interval_graph_${interval_graph_count}', {
						staticObjects: '',
						answerObjects: '{interval, $interval}',
						isStatic: true,
						snapSizeX: 1,
						snapSizeY: 1,
						xAxisLabel: '',
						yAxisLabel: 'y',
						numberLine: 1,
						useBracketEnds: 0,
						useFloodFill: 0,
						customGraphObjects: [
							['point', graphTool.pointTool.Point],
							['line', graphTool.lineTool.Line],
							['interval', graphTool.intervalTool.Interval],
						],
						JSXGraphOptions: {
							"boundingBox": [-6, 0.4, 6, -0.4],
							"defaultAxes": {
								"x": {
									"ticks": {
										"drawZero": 1,
										"label": {"anchorX": "middle", "anchorY": "top", "offset": [0,-12]},
										"majorHeight": 14,
										"minorHeight": 10,
										"minorTicks": 0,
										"scale": 1,
										"scaleSymbol": "",
										"strokeOpacity": 0.5,
										"strokeWidth": 2,
										"ticksDistance": 1
									}
								}
							},
							"grid": 0
						},
						ariaDescription: '$description',
					});
				};
				if (document.readyState === 'loading') window.addEventListener('DOMContentLoaded', initialize);
				else {
					const trampoline = () => {
						if (typeof window.graphTool === 'undefined') setTimeout(trampoline, 100);
						else initialize();
					}
					setTimeout(trampoline);
				}
			})();
		</script>
END_HTML
}
