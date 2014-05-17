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

qw(Doing what I mean usefully)
__END__

=head1 DESCRIPTION

Config::DWIM::Utility - Utility functions

=head1 FUNCTIONS

=head2 without_keys($hashref, @keys) => HashRef

Returns the hashref with the selected @keys removed

=head2 with_only_keys($hashref, @keys) => HashRef

Returns the hashref with only the selected @keys remaining
