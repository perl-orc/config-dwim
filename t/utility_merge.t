use Test::More;

use strict;
use warnings;

use Config::DWIM::Utility::Merge;

# Note: Tests are DELIBERATELY repeated boilerplate. Eases debugging.

sub merge_ar { return Config::DWIM::Utility::Merge::merge_arrayrefs(@_); }
sub merge_hr { return Config::DWIM::Utility::Merge::merge_hashrefs(@_); }
sub merge { return Config::DWIM::Utility::Merge::merge(@_); }
sub int_merge { return Config::DWIM::Utility::Merge::intelligent_merge(@_); }

my @test_ar = (
  [qw(foo bar)],
  [qw(bar baz)],
  [qw(baz quux)],
  [qw(quux foo)],
);

my @test_hr = (
  {qw(foo bar baz quux)},
  {qw(bar baz quux foo)},
  {qw(bar foo quux baz)},
  {qw(foo quux baz bar)},
);

my @out_hr = (
  {qw(foo bar baz quux foo quux baz bar)},
  {qw(foo quux baz bar foo bar baz quux)},
  {qw(bar foo quux baz bar baz quux foo)},
  {qw(bar baz quux foo bar foo quux baz)},
  {qw(bar baz quux foo foo quux baz bar)},
  {qw(foo quux baz bar bar baz quux foo)},
  {qw(bar foo quux baz foo bar baz quux)},
  {qw(foo bar baz quux bar foo quux baz)},
);

#1,3 r,l 0,2 l,r

my @test_s = \(qw(foo bar baz quux));

my @nested_tests = (
#0
  {
    in => [
      {
        foo => [qw(bar baz),[qw(quux)]],
        bar => {
          quux => 'baz',
          baz => 'quux',
        },
      },
      {
        foo => [qw(quux baz bar)],
        bar => {
          quux => 'bar',
          bar => 'foo',
        },
      },
      'r',
    ],
    out => {
      foo => [qw(quux baz bar)],
      bar => {
        quux => 'bar',
        baz => 'quux',
        bar => 'foo',
      },
    }
  },
#1
  {
    in => [
      {
        foo => 'bar',
        bar => [qw(baz quux)],
        baz => {
          foo => 'bar',
          bar => 'baz',
          baz => 'quux',
        },
      },
      {
        foo => [qw(bar)],
        bar => {
          quux => 'baz',
          baz => 'quux',
        },
        baz => {
          foo => 'baz',
          bar => 'bar',
          quux => 'quux',
        },
      },
      'l',
    ],
    out => {
      foo => [qw(bar)],
      bar => {
        quux => 'baz',
        baz => 'quux',
      },
      baz => {
        foo => 'bar',
        bar => 'baz',
        baz => 'quux',
        quux => 'quux',
      },
    }
  },
);

# Simple scoring tests
is_deeply(merge($test_ar[0],$test_hr[0],'l'), $test_hr[0]);
is_deeply(merge($test_hr[0],$test_ar[0],'r'), $test_hr[0]);
is_deeply(merge($test_s[0],$test_ar[0],'l'), $test_ar[0]);
is_deeply(merge($test_s[0],$test_hr[0],'r'), $test_hr[0]);

# Simple left/right priority tests
is_deeply(merge_ar($test_ar[0],$test_ar[1],'r'),$test_ar[1]);
is_deeply(merge_ar($test_ar[1],$test_ar[0],'l'),$test_ar[1]);
is_deeply(merge_ar($test_ar[0],$test_ar[1],'l'),$test_ar[0]);
is_deeply(merge_ar($test_ar[1],$test_ar[0],'r'),$test_ar[0]);
is_deeply(merge_hr($test_hr[0],$test_hr[3],'r'),$out_hr[0]);
is_deeply(merge_hr($test_hr[0],$test_hr[3],'l'),$out_hr[1]);
is_deeply(merge_hr($test_hr[1],$test_hr[2],'l'),$out_hr[2]);
is_deeply(merge_hr($test_hr[1],$test_hr[2],'r'),$out_hr[3]);

# Simple left/right priority merge tests
is_deeply(merge($test_ar[0],$test_ar[1],'r'),$test_ar[1]);
is_deeply(merge($test_ar[1],$test_ar[0],'l'),$test_ar[1]);
is_deeply(merge($test_ar[0],$test_ar[1],'l'),$test_ar[0]);
is_deeply(merge($test_ar[1],$test_ar[0],'r'),$test_ar[0]);
is_deeply(merge($test_hr[0],$test_hr[3],'r'),$out_hr[0]);
is_deeply(merge($test_hr[0],$test_hr[3],'l'),$out_hr[1]);
is_deeply(merge($test_hr[1],$test_hr[2],'l'),$out_hr[2]);
is_deeply(merge($test_hr[1],$test_hr[2],'r'),$out_hr[3]);
is_deeply(merge($test_hr[1],$test_hr[3],'r'),$out_hr[4]);
is_deeply(merge($test_hr[1],$test_hr[3],'l'),$out_hr[5]);
is_deeply(merge($test_hr[0],$test_hr[2],'l'),$out_hr[6]);
is_deeply(merge($test_hr[0],$test_hr[2],'r'),$out_hr[7]);

# Nested merge tests
use Data::Dumper 'Dumper';
is_deeply(merge(@{$nested_tests[0]->{'in'}}), $nested_tests[0]->{'out'});
is_deeply(merge(@{$nested_tests[1]->{'in'}}), $nested_tests[1]->{'out'});
# foreach my $test (@nested_tests) {
#   is_deeply(merge(@{$test->{'in'}}), $test->{'out'});
# }

# Merge with code

# Intelligent merge

done_testing;
