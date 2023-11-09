loadMacros('MathObjects.pl', 'parserMultiAnswer.pl');
Context()->strings->are(T => {}, F => {}, True => { alias => 'T' }, False => { alias => 'F' });

$Plabel = 'P';
$Qlabel = 'Q';

sub maTable {
	my ($label, $T1, $T2, $T3, $T4) = @_;
	return MultiAnswer(Compute($T1), Compute($T2), Compute($T3), Compute($T4))->with(
		singleResult     => 1,
		allowBlankAnswer => 1,
		checkTypes       => 1,
		format           =>
			printHtmlTable([ "\\($Plabel\\)", "\\($Qlabel\\)", "\\($label\\)" ], ['%s'], ['%s'], ['%s'], ['%s']),
		tex_format => printTexTable([ "$Plabel", "$Qlabel", "$label" ], ['%s'], ['%s'], ['%s'], ['%s']),
		checker    => sub {
			my ($correct, $student, $ansHash) = @_;
			my @c     = @{$correct};
			my @s     = @{$student};
			my $score = 0;
			for (my $i = 0; $i < 4; $i++) {
				$score++ if ($c[$i] == $s[$i]);
			}
			return $score / 4;
		}
	);
}

sub printHtmlTable {
	my ($labels, @rows) = @_;
	my $out =
		'<table class="pg-table" style="border: 2px solid; border-color: #000; text-align: center;">'
		. '<thead><tr><th style="border: 1px solid;">'
		. join('</th><th style="border: 1px solid;">', map { '\(' . $_ . '\)' } @$labels)
		. '</th></tr></thead><tbody>';
	my @rowHead = ([ 'T', 'T' ], [ 'T', 'F' ], [ 'F', 'T' ], [ 'F', 'F' ]);
	for (@rows) {
		my @row = (@{ shift(@rowHead) }, @$_);
		$out .= '<tr><td style="border: 1px solid">' . join('</td><td style="border: 1px solid">', @row) . '</td></tr>';
	}
	return "$out</tbody></table>";
}

sub printTexTable {
	my ($labels, @rows) = @_;
	my $cols    = scalar(@{ $rows[0] }) + 2;
	my $out     = '\begin{array}{|' . ('c|') x $cols . '} \hline ' . join(' & ', @$labels) . '\\\\ \hline ';
	my @rowHead = (
		[ '\text{T}', '\text{T}' ],
		[ '\text{T}', '\text{F}' ],
		[ '\text{F}', '\text{T}' ],
		[ '\text{F}', '\text{F}' ]
	);
	for (@rows) {
		my @row = (@{ shift(@rowHead) }, @$_);
		$out .= join(' & ', map { $_ =~ /^[TF]$/ ? "\\text{$_}" : $_ } @row) . ' \\\\ \hline ';
	}
	return "$out\\end{array}";
}

sub printTexTable2 {
	return '\(' . printTexTable(@_) . '\)';
}

sub printTables {
	my ($labels, $multi_answers) = @_;
	my @rows = ([ "\\quad $Plabel \\quad", "\\quad $Qlabel \\quad", @$labels ]);
	for (0 .. 3) {
		push(@rows, [ map { $_->ans_rule(1) } @{$multi_answers} ]);
	}
	return MODES(TeX => printTexTable2(@rows), HTML => printHtmlTable(@rows));
}

sub printTable {
	my ($label, $ma) = @_;
	return printTables([$label], [$ma]);
}

sub printAnsTables {
	my @cols = @_;
	my @rows = ([ "\\quad $Plabel \\quad", "\\quad $Qlabel \\quad", map { $_->[0] } @cols ]);
	for my $i (1 .. 4) {
		push(@rows, [ map { $_->[$i] } @cols ]);
	}
	return MODES(TeX => printTexTable2(@rows), HTML => printHtmlTable(@rows));
}

sub printAnsTable {
	return ref($_->[0]) eq 'ARRAY' ? printAnsTables(@_) : printAnsTables([@_]);
}

sub comboTable {
	my ($label, $T1, $T2, $T3, $T4) = @_;
	my $ma     = maTable($label, $T1, $T2, $T3, $T4);
	my $pTable = printTable($label, $ma);
	return ($ma, $pTable);
}
