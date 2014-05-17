package Config::DWIM::Utility::Merge;

sub merge_arrayrefs {
  my ($left, $right, $direction) = @_;
  return $left if $direction eq 'l';
  return $direction->($left,$right) if (ref($direction) eq 'CODE');
  # Default right
  return $right;
}

use Data::Dumper 'Dumper';

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
    warn "score: " . ref($s)."\n";
    return $s;
  }
  # Okay, they're both the same size. How big are they?
  if (ref($left) eq 'HASH') {
    warn "Hash\n";
    return merge_hashrefs($left,$right,$direction);
  }
  if (ref($left) eq 'ARRAY') {
    warn "Array\n";
    return merge_arrayrefs($left,$right,$direction);
  }
  # Scalars. Does left win? Or a callback?
  if ($direction eq 'l') {
    warn "Left\n";
    return $left;
  }
  if (ref($direction) eq 'CODE') {
    warn "CODE\n";
    return $direction->($left,$right);
  }
  warn "Right";
  # Default right
  return $right;
}

sub intelligent_merge {
  my ($left, $right) = @_;
  return _intelligent_merge()->($left,$right);
}

sub _intelligent_merge {
  my $im = sub {
	return merge(@_[0,1],$im);
  };
  return $im;
}

qw(I really don't know what you mean)
__END__
