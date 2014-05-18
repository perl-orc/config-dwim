use Test::More;

use Config::DWIM::Utility;

sub without {
  return Config::DWIM::Utility::without_keys(@_);
}
sub with {
  return Config::DWIM::Utility::with_only_keys(@_);
}
sub chunk {
  return Config::DWIM::Utility::chunk(@_);
}
sub reduce {
  return Config::DWIM::Utility::reduce(@_);
}
my %hash = qw(
  foo bar
  bar baz
  baz quux
  quux foo
);
my $forchunking = [1..16];
my $chunked = [
  [1,2], [3,4], [5,6], [7,8], [9,10], [11,12], [13,14], [15,16],
];
is_deeply(without(\%hash,qw(foo bar)), {qw(baz quux quux foo)});
is_deeply(without(\%hash,qw(pancake)), {%hash});
is_deeply(with(\%hash, qw(foo bar)), {qw(foo bar bar baz)});
is_deeply(with(\%hash, qw(baz quux)), {qw(baz quux quux foo)});
is_deeply(chunk($forchunking,2), $chunked);
is_deeply(chunk([@$forchunking,17],2), [@$chunked,[17]]);
is_deeply(chunk([],2),[]);
is_deeply(chunk(["a"],2),["a"]);

is(reduce(sub{ shift() + shift(); }, 1,2,3,4,5,6,7,8),36);

done_testing;
