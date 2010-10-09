#!perl -w

use Test::More qw/no_plan/;
use Test::Exception;
use Test::postgresql;
use File::Temp;

BEGIN {
    use_ok( 'App::PgCryobit' ) || print "Bail out!
";
}

my $temp_backup_dir = File::Temp::tempdir(CLEANUP =>1);
my $pgsql = Test::postgresql->new()
    or plan skip_all => $Test::postgresql::errstr;


## Try the same thing with a file path
my $cryo;

## In this one, the connect string is wrong.
lives_ok( sub{ $cryo = App::PgCryobit->new({ config_paths => ['conf_test/pg_cryobit_faulty.conf'] }); }, "Lives with good test config");
ok( my $conf = $cryo->configuration() , "Conf is loaded");
is( $cryo->feature_checkconfig() , 1 , "Check config is not OK"); 

## In this one, there is a missing backup dir in the configuration.
lives_ok( sub{ $cryo = App::PgCryobit->new({ config_paths => ['conf_test/pg_cryobit_faulty2.conf'] }); }, "Lives with good test config");
ok( $conf = $cryo->configuration() , "Conf is loaded");
ok( $cryo->configuration()->{dsn} = $pgsql->dsn() , "Ok setting DSN with test server");
ok( $cryo->configuration()->{data_directory} = $pgsql->base_dir(), "Ok setting the base dir to the one of the test harness");
is( $cryo->feature_checkconfig() , 1 , "Check config is not OK Because of missing backup_dir"); 

## In this one, the backup_dir from the configuration is wrong.

lives_ok( sub{ $cryo = App::PgCryobit->new({ config_paths => ['conf_test/pg_cryobit.conf'] }); }, "Lives with good test config");
ok( $conf = $cryo->configuration() , "Conf is loaded");
is( $cryo->feature_checkconfig(), 1 , "Impossible to connect without a good DSN");
diag("Setting conf dsn to ".$pgsql->dsn());
ok( $cryo->configuration()->{dsn} = $pgsql->dsn() , "Ok setting DSN with test server");
is( $cryo->feature_checkconfig() , 1 , "Still does not pass the test. We need a good directory"); 
ok( $cryo->configuration()->{data_directory} = $pgsql->base_dir(), "Ok setting the base dir to the one of the test harness");
is ( $cryo->feature_checkconfig(), 1 , "All is not fine, the backup_dir in config is wrong");

## A last one with everything correct

lives_ok( sub{ $cryo = App::PgCryobit->new({ config_paths => ['conf_test/pg_cryobit.conf'] }); }, "Lives with good test config");
ok( $conf = $cryo->configuration() , "Conf is loaded");
is( $cryo->feature_checkconfig(), 1 , "Impossible to connect without a good DSN");
diag("Setting conf dsn to ".$pgsql->dsn());
ok( $cryo->configuration()->{dsn} = $pgsql->dsn() , "Ok setting DSN with test server");
is( $cryo->feature_checkconfig() , 1 , "Still does not pass the test. We need a good directory"); 
ok( $cryo->configuration()->{data_directory} = $pgsql->base_dir(), "Ok setting the base dir to the one of the test harness");
ok( $cryo->configuration()->{shipper}->{backup_dir} = $temp_backup_dir , "Ok setting the backup_dir");
is ( $cryo->feature_checkconfig(), 0 , "All is file");
