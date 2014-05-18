package Config::DWIM::Utility::Merge;

use Config::DWIM::Hashject;

sub merge_hashrefs {
  my ($left, $right, $direction) = @_;
  my %new = (%$left, %$right);
  foreach my $k (keys %new) {
	$new{$k} = merge($left->{$k}, $right->{$k}, $direction);
  }
  return {%new};
}

sub score {
  return 3 if ref($_[0]) eq 'HASH';
  return 2 if ref($_[0]) eq 'ARRAY';
  return 1 if defined $_[0];
  return 0;
}

sub _score {
  my ($left, $right) = @_;
  return $left if score($left) > score($right);
  return $right if score($right) > score($left);
  return;
}

sub merge {
  my ($left, $right, $direction) = @_;
  if (my $s = _score($left, $right)) {
    return $s;
  }
  # Okay, they're both the same size.
  # If they're hashes, we have to attempt to merge
  if (ref($left) eq 'HASH') {
    return merge_hashrefs($left,$right,$direction);
  }
  # Otherwise, are we supposed to go left?
  if ($direction eq 'l') {
    return $left;
  }
  # Are we supposed to call it back?
  if (ref($direction) eq 'CODE') {
    return $direction->($left,$right);
  }
  # Default right
  return $right;
}

sub _process_ar {
  my $thing = shift;
  my @ret = map process($_), @$thing;
  return [@ret];
}

sub _process_hr {
  my $thing = shift;
  my @ret;
  foreach my $k (keys %$thing) {
	@ret = (@ret, $k, process($thing->{$k}));
  }
  my $ret = Config::DWIM::Hashject->new([@ret]);
  $ret;
}

sub process {
  my $thing = shift;
  return _process_hr($thing) if ref($thing) eq 'HASH';
  return _process_ar($thing) if ref($thing) eq 'ARRAY';
  return $thing;
}

qw(I really don't know what you mean)
__END__
