=head1 DESCRIPTION

Creates a new RealStrings context in which only variable
constants are accepted as real numbers. In this context
first assign all constants you wish to use a unique real
number, then you can use those constants in lists and
sets as if they were a number, but all output will be the
constant.

=cut

sub _contextRealStrings_init { context::Strings::Real::Init() };

package context::Strings::Real;

sub Init {
	my $context = $main::context{RealStrings} = Parser::Context->getCopy('Numeric');
	$context->flags->set(
		formatStudentAnswer => 'parsed',
		NumberCheck => sub {
			my $self = shift;
			$self->Error('Numbers are not allowed in this answer.');
		}
	);
	$context->variables->clear;
	$context->functions->disable('All');
	$context->operators->undefine($context->operators->names);
	$context->operators->redefine(',');
	$context->strings->clear;
	$context->constants->clear;
	$context->parens->set('{' => {type => 'Set', removable => 0, emptyOK => 1, close => '}'});
	$context->{cmpDefaults}{Set} = {cmp_class => 'Finite Set'};
	$context->{value}{Real} = 'Value::Strings::Real';
}

# Modifications to add augment line to matrices
package Value::Strings::Real;
our @ISA = ('Value::Real');

sub genConstHash {
	my $self = shift;
	foreach($self->context->constants->names) {
		my $val = $self->context->constants->value($_);
		$self->{constHash}{$val} = $_;
	}
}
sub string {
	my $self    = shift;
	my $n       = $self->{data}[0];
	$self->genConstHash unless (defined($self->{constHash}) && $self->{constHash}{$n});
	return $self->{constHash}{$n} if ($self->{constHash}{$n});
	return $self->SUPER::string(@_);
}

sub TeX {
	my $n = (shift)->string(@_);
	return "\\text{$n}";
}

1;
