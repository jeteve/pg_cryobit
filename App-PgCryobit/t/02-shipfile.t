#!perl -w

use Test::More tests => 12;
use Test::Exception;
use Test::postgresql;
use File::Temp;

BEGIN {
    use_ok( 'App::PgCryobit' ) || print "Bail out!
";
}

my $temp_backup_dir = File::Temp::tempdir(CLEANUP =>1);
diag("Building a test instance of PostgreSQL. This will take a while");
my $pgsql = Test::postgresql->new()
    or plan skip_all => $Test::postgresql::errstr;


## Try the same thing with a file path
my $cryo;

lives_ok( sub{ $cryo = App::PgCryobit->new({ config_paths => ['conf_test/pg_cryobit.conf'] }); }, "Lives with good test config");
ok(my $conf = $cryo->configuration() , "Conf is loaded");
ok( $cryo->configuration()->{dsn} = $pgsql->dsn() , "Ok setting DSN with test server");
ok( $cryo->configuration()->{data_directory} = $pgsql->base_dir(), "Ok setting the base dir to the one of the test harness");
ok( $cryo->configuration()->{shipper}->{backup_dir} = $temp_backup_dir , "Ok setting the backup_dir");
is ( $cryo->feature_checkconfig(), 0 , "All is fine in config");

my ($fh, $filename) = File::Temp::tempfile();

ok( $cryo->options( { file =>  'pouleaupot' } ) , "Ok setting options");
is( $cryo->feature_archivewal() , 1 , "Archiving a non existing file is not OK");
ok( $cryo->options( { file => $filename } ), "Ok setting options");

is( $cryo->feature_archivewal(), 0 , "Archiving has succedeed");
## Archiving a second time the same file should crash
is( $cryo->feature_archivewal(), 1, "Second archiving of the same file is impossible");
