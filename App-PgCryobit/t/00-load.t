#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::PgCryobit' ) || print "Bail out!
";
}

diag( "Testing App::PgCryobit $App::PgCryobit::VERSION, Perl $], $^X" );
