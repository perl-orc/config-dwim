use Test::More;
use Test::Differences;

use Config::DWIM::Hashject;

my $h = Config::DWIM::Hashject->new([
  foo => 'bar',
  bar => 'baz',
  foo_bar => 'baz_quux1',
  "foo:__-:bar" => 'baz_quux2',
]);
use Data::Dumper 'Dumper';
warn Dumper \%Config::DWIM::Hashject::gensym1;
is($h->foo,'bar');
is($h->bar,'baz');
# This also tests order preservation. But not that well
eq_or_diff($h->foo_bar, ['baz_quux1', 'baz_quux2']);
is($h->can('baz'),undef);

done_testing;
