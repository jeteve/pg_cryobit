#!perl -w
use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN{
  eval{ require Test::PostgreSQL; };
  if( $@ ){
    plan skip_all => 'No Test::PostgreSQL';
    done_testing();
  }
}
use File::Temp;
use Log::Log4perl qw/:easy/;
Log::Log4perl->easy_init($TRACE);

use App::PgCryobit;



my $test_lib_dir = File::Spec->rel2abs('./lib/');

my ( $tc_fh , $tc_file ) = File::Temp::tempfile(CLEANUP => 1);

my $temp_backup_dir = File::Temp::tempdir(CLEANUP =>1);

{
  my $cryo;
  ## One with multishipper containing one shipper only
  lives_ok( sub{ $cryo = App::PgCryobit->new({ config_paths => ['conf_test/pg_cryobit_multi_unique.conf'] }); }, "Lives with good multi config");
  is( $cryo->feature_checkshipper(), 1 , "Checking shipper is because of bad backup dir in subshippers");
  foreach my $shipper ( @{$cryo->shipper()->shippers()} ){
    my $temp_backup = File::Temp::tempdir(CLEANUP => 1);
    $shipper->backup_dir($temp_backup);
  }
  is( $cryo->feature_checkshipper() , 0, "How multishipper is good");
}


{
  my $cryo;
  ## One with multishipper
  lives_ok( sub{ $cryo = App::PgCryobit->new({ config_paths => ['conf_test/pg_cryobit_multi.conf'] }); }, "Lives with good multi config");
  is( $cryo->feature_checkshipper(), 1 , "Checking shipper is because of bad backup dir in subshippers");
  foreach my $shipper ( @{$cryo->shipper()->shippers()} ){
    my $temp_backup = File::Temp::tempdir(CLEANUP => 1);
    $shipper->backup_dir($temp_backup);
  }
  is( $cryo->feature_checkshipper() , 0, "How multishipper is good");
}

{
  my $cryo;
  ## A last one with everything correct
  lives_ok( sub{ $cryo = App::PgCryobit->new({ config_paths => ['conf_test/pg_cryobit.conf'] }); }, "Lives with good test config");
  ok( my $conf = $cryo->configuration() , "Conf is loaded");
  is( $cryo->feature_checkshipper(), 1 , "Directory is not good");
  ok( $cryo->shipper->backup_dir( $temp_backup_dir ) , "Ok setting the backup_dir");
  ok( ! $cryo->feature_checkshipper() , "Ok shipper is all fine");
}

done_testing();

