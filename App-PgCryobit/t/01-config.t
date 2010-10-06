#!perl -w

use Test::More qw/no_plan/;
use Test::Exception;
use Test::postgresql;

BEGIN {
    use_ok( 'App::PgCryobit' ) || print "Bail out!
";
}

my $pgsql = Test::postgresql->new()
    or plan skip_all => $Test::postgresql::errstr;


## Try the same thing with a file path
my $cryo;
lives_ok( sub{ $cryo = App::PgCryobit->new({ config_paths => ['conf_test/pg_cryobit_faulty.conf'] }); }, "Lives with good test config");
ok( my $conf = $cryo->configuration() , "Conf is loaded");
is( $cryo->feature_checkconfig() , 1 , "Check config is not OK"); 

lives_ok( sub{ $cryo = App::PgCryobit->new({ config_paths => ['conf_test/pg_cryobit.conf'] }); }, "Lives with good test config");
ok( $conf = $cryo->configuration() , "Conf is loaded");
diag("Setting conf dsn to ".$pgsql->dsn());
ok( $cryo->configuration()->{dsn} = $pgsql->dsn() , "Ok setting DSN with test server");
is( $cryo->feature_checkconfig() , 0 , "Check config is OK"); 
