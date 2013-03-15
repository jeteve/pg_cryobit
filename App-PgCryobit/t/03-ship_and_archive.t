#!perl -w

use Test::More;
use Test::Exception;
BEGIN{
  eval{ require Test::postgresql; };
  if( $@ ){
    plan skip_all => 'No Test::postgresql';
    done_testing();
  }
}

use File::Temp;
use File::Spec;
use Log::Log4perl qw/:easy/;
Log::Log4perl->easy_init($DEBUG);

BEGIN {
    use_ok( 'App::PgCryobit' ) || BAIL_OUT("Cannot load main application class");
}

my $script_file = File::Spec->rel2abs( './script/pg_cryobit' ) ;
unless( -f $script_file && -x $script_file ){
    BAIL_OUT($script_file." is not executable or does not exists");
}
my $test_lib_dir = File::Spec->rel2abs('./lib/');

my $temp_backup_dir = File::Temp::tempdir(CLEANUP =>1);
my $temp_snapshooting_dir = File::Temp::tempdir(CLEANUP =>1);
## This temporary configuration file will hold the correct configuration
## within this test postgresql instance.
my ( $tc_fh , $tc_file ) = File::Temp::tempfile(CLEANUP => 1);

diag("Building a test instance of PostgreSQL. Expect about one minute");
diag("Do not pay attention to the error messages if the test passes");

my $pgsql;

my $pg_args = ' -c archive_mode=on -c archive_command=\'perl -I'.$test_lib_dir.' '.$script_file.' archivewal --file=%p --conf='.$tc_file.'\'';


eval{
  $pgsql = Test::postgresql->new(
                                 postmaster_args => $Test::postgresql::Defaults{postmaster_args} .$pg_args
                                );
};
if ( $@ ) {
  diag(q|Failed to build postgresql without wal_level. Trying with it.
It is fine if you are using Postgresql 9.*|);
  $pgsql = Test::postgresql->new(
                                 postmaster_args => $Test::postgresql::Defaults{postmaster_args} . ' -c wal_level=archive ' . $pg_args
                                );
}

$pgsql or plan skip_all => $Test::postgresql::errstr;


## Try the same thing with a file path
my $cryo;

lives_ok( sub{ $cryo = App::PgCryobit->new({ config_paths => ['conf_test/pg_cryobit.conf'] }); }, "Lives with good test config");
ok(my $conf = $cryo->configuration() , "Conf is loaded");
ok( $cryo->configuration()->{dsn} = $pgsql->dsn() , "Ok setting DSN with test server");
ok( $cryo->configuration()->{data_directory} = $pgsql->base_dir().'/data/' , "Ok setting the base dir to the one of the test harness");
ok( $cryo->configuration()->{shipper}->{backup_dir} = $temp_backup_dir , "Ok setting the backup_dir");
## Setting up the snapshooting_dir
ok( $cryo->configuration()->{snapshooting_dir} = $temp_snapshooting_dir, "Ok setting the temp snapshooting dir");

## Dump the right config to the temp conf file used by the database.
$cryo->config_general()->save_file($tc_file, $cryo->configuration());
is ( $cryo->feature_checkconfig(), 0 , "All is fine in config");


my ($fh, $filename) = File::Temp::tempfile();

ok( $cryo->options( { file =>  'pouleaupot' } ) , "Ok setting options");
is( $cryo->feature_archivewal() , 1 , "Archiving a non existing file is not OK");
ok( $cryo->options( { file => $filename , deepclean => 1 } ), "Ok setting options");

is( $cryo->feature_archivewal(), 0 , "Archiving has succedeed");
## Archiving a second time the same file should crash
is( $cryo->feature_archivewal(), 1, "Second archiving of the same file is impossible");
## Testing rotation of wal
is( $cryo->feature_rotatewal(), 0 , "Rotating wal is OK" );
## And another one
is( $cryo->feature_rotatewal(), 0 , "Rotating a second time is OK");
is( $cryo->feature_archivesnapshot(), 0 , "Taking a snapshot and archiving it is OK");
$pgsql->stop();

done_testing();
