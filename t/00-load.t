#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Config::DWIM' ) || print "Bail out!\n";
}

diag( "Testing Config::DWIM $Config::DWIM::VERSION, Perl $], $^X" );
