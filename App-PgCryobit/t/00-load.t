#!perl -T

use Test::More tests => 8;
use Test::Exception;
BEGIN {
    use_ok( 'App::PgCryobit' ) || print "Bail out!
";
}

diag( "Testing App::PgCryobit $App::PgCryobit::VERSION, Perl $], $^X" );

my $cryo;
dies_ok( sub{ $cryo = App::PgCryobit->new(); }, "Dies without config paths");
lives_ok( sub{ $cryo = App::PgCryobit->new({ config_paths => [ '/ojfjj/' ] });}, "Lives with good config");
dies_ok( sub{ my $conf = $cryo->configuration(); } , "Dies on building the conf");
## Replaces it with a correct conf one.
lives_ok( sub{ $cryo = App::PgCryobit->new({ config_paths => ['conf_test'] }); }, "Lives with good test config");
ok( my $conf = $cryo->configuration() , "Conf is loaded");
## Try the same thing with a file path
lives_ok( sub{ $cryo = App::PgCryobit->new({ config_paths => ['conf_test/pg_cryobit.conf'] }); }, "Lives with good test config");
ok( $conf = $cryo->configuration() , "Conf is loaded");
