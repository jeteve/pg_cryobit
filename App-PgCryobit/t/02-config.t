#!perl -w

use Test::More tests => 24;
use Test::Exception;
use Test::postgresql;
use File::Temp;

BEGIN {
    use_ok( 'App::PgCryobit' ) || print "Bail out!
";
}

my $script_file = File::Spec->rel2abs( './script/pg_cryobit' ) ;
unless( -f $script_file && -x $script_file ){
    BAIL_OUT($script_file." is not executable or does not exists");
}

my $test_lib_dir = File::Spec->rel2abs('./lib/');

my ( $tc_fh , $tc_file ) = File::Temp::tempfile();

my $temp_backup_dir = File::Temp::tempdir(CLEANUP =>1);
diag("Building a test instance of PostgreSQL. Expect about one minute");
diag("Do not pay attention to the error messages if the test passes");
my $pgsql = Test::postgresql->new(
    postmaster_args => $Test::postgresql::Defaults{postmaster_args} . ' -c archive_mode=on -c archive_command=\'perl -I'.$test_lib_dir.' '.$script_file.' archivewal --file=%p --conf='.$tc_file.'\''
    )
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
## Dump the right config to the temp conf file used by the database.
$cryo->config_general()->save_file($tc_file, $cryo->configuration());
is ( $cryo->feature_checkconfig(), 0 , "All is file");
