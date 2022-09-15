loadMacros('MathObjects.pl', 'parserMultiAnswer.pl');
Context()->strings->are(T => {}, F => {}, True => {alias => 'T'}, False => {alias => 'F'});

$Plabel = 'P';
$Qlabel = 'Q';

sub maTable {
	my ($label, $T1, $T2, $T3, $T4) = @_;
	return MultiAnswer(Compute($T1), Compute($T2), Compute($T3), Compute($T4))->with(
		singleResult => 1,
		allowBlankAnswer => 1,
		checkTypes => 1,
		format => '<table class="mx-auto" border="1" style="text-align: center;">'
			. '<thead><tr><th style="border-color: #000;">\( ' . $Plabel . ' \)</th>'
			. '<th style="border-color: #000;">\( ' . $Qlabel . ' \)</th>'
			. '<th style="border-color: #000;">\(' . $label . '\)</th></thead>'
			. '<tbody><tr><td style="border-color: #000;">T</td>'
			. '<td style="border-color: #000;">T</td>'
			. '<td style="border-color: #000;">%s</td></tr>'
			. '<tr><td style="border-color: #000;">T</td>'
			. '<td style="border-color: #000;">F</td>'
			. '<td style="border-color: #000;">%s</td></tr>'
			. '<tr><td style="border-color: #000;">F</td>'
			. '<td style="border-color: #000;">T</td>'
			. '<td style="border-color: #000;">%s</td></tr>'
			. '<tr><td style="border-color: #000;">F</td>'
			. '<td style="border-color: #000;">F</td>'
			. '<td style="border-color: #000;">%s</td></tr></tbody></table>',
		tex_format => '\begin{array}{|c|c|c|} \hline ' . $Plabel . ' & ' . $Qlabel
			. ' & ' . $label . ' \\\\ \hline '
			. '\text{T} & \text{T} & %s \\\\ \hline '
			. '\text{T} & \text{F} & %s \\\\ \hline '
			. '\text{F} & \text{T} & %s \\\\ \hline '
			. '\text{F} & \text{F} & %s \\\\ \hline\end{array}',
		checker => sub {
			my ($correct, $student, $ansHash) = @_;
			my @c = @{$correct};
			my @s = @{$student};
			my $score = 0;
			for (my $i = 0; $i < 4; $i++) {
				$score++ if ($c[$i] == $s[$i]);
			}
			return $score / 4;
		}
	);
}

sub printTables {
	my @labels = @{$_[0]};
	my @mas = @{$_[1]};
	my $cols = scalar @labels;
	my @rowHeader = (
		["\\(\\quad $Plabel \\quad\\)","\\(\\quad $Qlabel \\quad\\)"],
		['T','T'], ['T','F'], ['F','T'], ['F','F']
	);
	my $pTable = begintable($cols + 2);
	for (my $j = 0; $j < 5; $j++) {
		my @newRow = @{$rowHeader[$j]};
		for (my $i = 0; $i < $cols; $i++) {
			if ($j == 0) {
				push(@newRow, "\\( $labels[$i] \\)");
			} else {
				push(@newRow, $mas[$i]->ans_rule(1));
			}
		}
		$pTable .= row(@newRow);
	}
	$pTable .= endtable();
	return $pTable;
}

sub printTable {
	my ($label, $ma) = @_;
	return printTables([$label], [$ma]);
}

sub printAnsTables {
	my @cols = @_;
	my $ncols = scalar @cols;
	my @rowHeader = (
		["\\(\\quad $Plabel \\quad\\)","\\(\\quad $Qlabel \\quad\\)"],
		['T','T'], ['T','F'], ['F','T'], ['F','F']
	);
	my $pTable = begintable($ncols + 2);
	for (my $j = 0; $j < 5; $j++) {
		my @newRow = @{$rowHeader[$j]};
		for (my $i = 0; $i < $ncols; $i++) {
			if ($j == 0) {
				push(@newRow, "\\( $cols[$i][$j] \\)");
			} else {
				push(@newRow, $cols[$i][$j]);
			}
		}
		$pTable .= row(@newRow);
	}
	$pTable .= endtable();
	return $pTable;
}

sub printAnsTable {
	return printAnsTables(@_);
}

sub comboTable {
	my ($label, $T1, $T2, $T3, $T4) = @_;
	my $ma = maTable($label, $T1, $T2, $T3, $T4);
	my $pTable = printTable($label, $ma);
	return ($ma, $pTable);
}
