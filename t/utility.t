use Test::More;

use Config::DWIM::Utility;

sub without {
  return Config::DWIM::Utility::without_keys(@_);
}
sub with {
  return Config::DWIM::Utility::with_only_keys(@_);
}

my %hash = qw(
  foo bar
  bar baz
  baz quux
  quux foo
);

is_deeply(without(\%hash,qw(foo bar)), {qw(baz quux quux foo)});
is_deeply(without(\%hash,qw(pancake)), {%hash});
is_deeply(with(\%hash, qw(foo bar)), {qw(foo bar bar baz)});
is_deeply(with(\%hash, qw(baz quux)), {qw(baz quux quux foo)});

done_testing;
