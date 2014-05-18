package Config::DWIM::Utility;

sub without_keys {
  my ($hashref, @keys) = @_;
  my %hash = %$hashref;
  delete $hash{$_} for @keys;
  return {%hash};
}

sub with_only_keys {
  my ($hashref, @keys) = @_;
  my %hash = %$hashref;
  delete $hash{$_} foreach (keys %{(without_keys($hashref,@keys))});
  return {%hash};
}

sub chunk {
  my ($arrayref, $size) = @_;
  return [$arrayref] unless ($size > 0);
  return [$arrayref] unless @$arrayref > $size;
  my @new;
  my @working = @$arrayref;
  while (@working) {
	my @scratch;
    for (my $i = 0; $i < $size ; $i++) {
      last unless @working;
      push @scratch, shift @working;
	}
	push @new, [@scratch];
  }
  return [@new];
}

sub reduce {
  my ($f, $accum, $args, @rest) = @_;
  return $accum if !$args;
  my $ret = $f->($accum, ref($args) eq 'ARRAY' ? @$args : $args);
  return reduce($f, $ret, @rest);
}

qw(Doing what I mean usefully)
__END__

=head1 DESCRIPTION

Config::DWIM::Utility - Utility functions

=head1 FUNCTIONS

=head2 without_keys($hashref, @keys) => HashRef

Returns the hashref with the selected @keys removed

=head2 with_only_keys($hashref, @keys) => HashRef

Returns the hashref with only the selected @keys remaining

=head2 chunk(ArrayRef[Any], $size: Int) => ArrayRef[ArrayRef[Any]]

Splits the arrayref into chunks of maximum $size, returns as an arrayref of arrayrefs

=head2 reduce($f: Function, @args: ArrayRef[ArrayRef[Any]]) => Any

Applies one of @args to $f. Attempts to be smart, that is passing an arrayref passes a list. You can double-arrayref to get around that if you need to.
