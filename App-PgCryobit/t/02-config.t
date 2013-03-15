#!perl -w

#use Test::More qw/no_plan/;
use App::PgCryobit;

use Test::More;
use Test::Exception;

use File::Temp;
use Log::Log4perl qw/:easy/;
Log::Log4perl->easy_init($INFO);

BEGIN {
  eval{ require Test::postgresql; };
  if( $@ ){
    plan skip_all => 'No Test::postgresql';
    done_testing();
  }
}


my $script_file = File::Spec->rel2abs( './script/pg_cryobit' ) ;
unless( -f $script_file && -x $script_file ){
    BAIL_OUT($script_file." is not executable or does not exists");
}

my $test_lib_dir = File::Spec->rel2abs('./lib/');

my ( $tc_fh , $tc_file ) = File::Temp::tempfile(CLEANUP => 1);

my $temp_backup_dir = File::Temp::tempdir(CLEANUP =>1);
diag("Building a test instance of PostgreSQL. Expect about one minute");
diag("Do not pay attention to the error messages if the test passes");


my $pgsql;

my $pg_args = ' -c archive_mode=on -c archive_command=\'perl -I'.$test_lib_dir.' '.$script_file.' archivewal --file=%p --conf='.$tc_file.'\'' ;

diag("Building a test instance of postgresql");
eval{
  $pgsql = Test::postgresql->new(
                                 postmaster_args => $Test::postgresql::Defaults{postmaster_args} .$pg_args
                                );
};
if ( $@ ) {
  diag(q|Failed to build postgresql without wal_level. Trying with it.
This is fine if you are using Postgresql 9.* |);
  $pgsql = Test::postgresql->new(
                                 postmaster_args => $Test::postgresql::Defaults{postmaster_args} . ' -c wal_level=archive ' . $pg_args
                                );
}

$pgsql or plan skip_all => $Test::postgresql::errstr;


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
diag("Saving good config to $tc_file");
$cryo->config_general()->save_file($tc_file, $cryo->configuration());
is ( $cryo->feature_checkconfig(), 0 , "All is fine");
$pgsql->stop();

done_testing();
