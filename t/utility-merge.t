use Test::More;
use Test::Differences;

use strict;
use warnings;

use Config::DWIM::Utility::Merge;

# Note: Tests are DELIBERATELY repeated boilerplate. Eases debugging.

sub merge_hr { return Config::DWIM::Utility::Merge::merge_hashrefs(@_); }
sub merge { return Config::DWIM::Utility::Merge::merge(@_); }
sub process { return Config::DWIM::Utility::Merge::process(@_); }

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
eq_or_diff(merge($test_ar[0],$test_hr[0],'l'), $test_hr[0]);
eq_or_diff(merge($test_hr[0],$test_ar[0],'r'), $test_hr[0]);
eq_or_diff(merge($test_s[0],$test_ar[0],'l'), $test_ar[0]);
eq_or_diff(merge($test_s[0],$test_hr[0],'r'), $test_hr[0]);

# Simple left/right priority tests
eq_or_diff(merge($test_ar[0],$test_ar[1],'r'),$test_ar[1]);
eq_or_diff(merge($test_ar[1],$test_ar[0],'l'),$test_ar[1]);
eq_or_diff(merge($test_ar[0],$test_ar[1],'l'),$test_ar[0]);
eq_or_diff(merge($test_ar[1],$test_ar[0],'r'),$test_ar[0]);
eq_or_diff(merge_hr($test_hr[0],$test_hr[3],'r'),$out_hr[0]);
eq_or_diff(merge_hr($test_hr[0],$test_hr[3],'l'),$out_hr[1]);
eq_or_diff(merge_hr($test_hr[1],$test_hr[2],'l'),$out_hr[2]);
eq_or_diff(merge_hr($test_hr[1],$test_hr[2],'r'),$out_hr[3]);

# Simple left/right priority merge tests
eq_or_diff(merge($test_hr[0],$test_hr[3],'r'),$out_hr[0]);
eq_or_diff(merge($test_hr[0],$test_hr[3],'l'),$out_hr[1]);
eq_or_diff(merge($test_hr[1],$test_hr[2],'l'),$out_hr[2]);
eq_or_diff(merge($test_hr[1],$test_hr[2],'r'),$out_hr[3]);
eq_or_diff(merge($test_hr[1],$test_hr[3],'r'),$out_hr[4]);
eq_or_diff(merge($test_hr[1],$test_hr[3],'l'),$out_hr[5]);
eq_or_diff(merge($test_hr[0],$test_hr[2],'l'),$out_hr[6]);
eq_or_diff(merge($test_hr[0],$test_hr[2],'r'),$out_hr[7]);

# Nested merge tests
eq_or_diff(merge(@{$nested_tests[0]->{'in'}}), $nested_tests[0]->{'out'});
eq_or_diff(merge(@{$nested_tests[1]->{'in'}}), $nested_tests[1]->{'out'});

# Merge with code

sub dir_l {
  return shift;
}
sub dir_r {
  shift;
  return shift;
}

eq_or_diff(merge($test_ar[0],$test_ar[1],\&dir_r),$test_ar[1]);
eq_or_diff(merge($test_ar[1],$test_ar[0],\&dir_l),$test_ar[1]);
eq_or_diff(merge($test_ar[0],$test_ar[1],\&dir_l),$test_ar[0]);
eq_or_diff(merge($test_ar[1],$test_ar[0],\&dir_r),$test_ar[0]);
eq_or_diff(merge($test_hr[0],$test_hr[3],\&dir_r),$out_hr[0]);
eq_or_diff(merge($test_hr[0],$test_hr[3],\&dir_l),$out_hr[1]);
eq_or_diff(merge($test_hr[1],$test_hr[2],\&dir_l),$out_hr[2]);
eq_or_diff(merge($test_hr[1],$test_hr[2],\&dir_r),$out_hr[3]);
eq_or_diff(merge($test_hr[1],$test_hr[3],\&dir_r),$out_hr[4]);
eq_or_diff(merge($test_hr[1],$test_hr[3],\&dir_l),$out_hr[5]);
eq_or_diff(merge($test_hr[0],$test_hr[2],\&dir_l),$out_hr[6]);
eq_or_diff(merge($test_hr[0],$test_hr[2],\&dir_r),$out_hr[7]);

# Processing - Simple tests

my @samples = map process($out_hr[$_]), 0..7;

isa_ok($samples[0], 'Config::DWIM::Hashject');
isa_ok($samples[1], 'Config::DWIM::Hashject');
isa_ok($samples[2], 'Config::DWIM::Hashject');
isa_ok($samples[3], 'Config::DWIM::Hashject');
isa_ok($samples[4], 'Config::DWIM::Hashject');
isa_ok($samples[5], 'Config::DWIM::Hashject');
isa_ok($samples[6], 'Config::DWIM::Hashject');
isa_ok($samples[7], 'Config::DWIM::Hashject');
eq_or_diff([sort {$a cmp $b} $samples[0]->keys], [sort {$a cmp $b} keys %{$out_hr[0]}]); 
eq_or_diff([sort {$a cmp $b} $samples[1]->keys], [sort {$a cmp $b} keys %{$out_hr[1]}]); 
eq_or_diff([sort {$a cmp $b} $samples[2]->keys], [sort {$a cmp $b} keys %{$out_hr[2]}]); 
eq_or_diff([sort {$a cmp $b} $samples[3]->keys], [sort {$a cmp $b} keys %{$out_hr[3]}]); 
eq_or_diff([sort {$a cmp $b} $samples[4]->keys], [sort {$a cmp $b} keys %{$out_hr[4]}]); 
eq_or_diff([sort {$a cmp $b} $samples[5]->keys], [sort {$a cmp $b} keys %{$out_hr[5]}]); 
eq_or_diff([sort {$a cmp $b} $samples[6]->keys], [sort {$a cmp $b} keys %{$out_hr[6]}]); 
eq_or_diff([sort {$a cmp $b} $samples[7]->keys], [sort {$a cmp $b} keys %{$out_hr[7]}]); 

# Processing - Nesting

my $nested = {
  foo => [
    {
      baz => 'quux',
    },
  ],
};

my $h = process($nested);

isa_ok($h, 'Config::DWIM::Hashject');
eq_or_diff([$h->keys], [keys %$nested]);
is(ref($h->foo), 'ARRAY');
isa_ok($h->foo->[0], 'Config::DWIM::Hashject');
is($h->foo->[0]->baz, 'quux');

done_testing;
