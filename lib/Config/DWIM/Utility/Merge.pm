package Config::DWIM::Utility::Merge;

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

qw(I really don't know what you mean)
__END__
