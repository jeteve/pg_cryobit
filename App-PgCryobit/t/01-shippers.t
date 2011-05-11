#!perl -w

use Test::More;
use Test::Exception;
use File::Temp;
use File::Basename;
use Test::FTP::Server;
use Test::TCP;

use App::PgCryobit::Shipper::FTPShipper;
use App::PgCryobit::Shipper::CopyShipper;

my $user = 'dale';
my $pass = 'cooper';
my $sandbox_base = File::Temp::tempdir( DIR => 't/remote_ftp' , CLEANUP => 1 );
mkdir $sandbox_base.'/backup';

test_tcp
  (
   server
   => sub{
          my $port = shift;
          Test::FTP::Server->new(
                                 'users' => [{
                                              'user' => $user,
                                              'pass' => $pass,
                                              'sandbox' => $sandbox_base,
                                             }],
                                 'ftpd_conf' => {
                                                 'port' => $port,
                                                 'daemon mode' => 1,
                                                 'run in background' => 0,
                                                },
                                )->run();
         },
   client
   => sub{
          my $port = shift;
          ## Test ftp shipper.
          my $ftp_shipper = App::PgCryobit::Shipper::FTPShipper
          ->new({
                 ftp_host => 'localhost',
                 ftp_port => $port,
                 ftp_user => 'dale',
                 ftp_password => 'cooper',
                 backup_dir => 'backup'
                });

          my $copy_save_dir = File::Temp::tempdir( DIR => 't/remote_ftp' , CLEANUP => 1 );
          my $copy_shipper = App::PgCryobit::Shipper::CopyShipper
          ->new({
                 backup_dir => $copy_save_dir
                });

          foreach my $shipper ( $ftp_shipper , $copy_shipper ) {

            lives_ok(sub{ $shipper->check_config(); } , "Check config is OK");
            ok( my $xlog_dir = $shipper->xlog_dir() , "Xlog dir is defined");
            cmp_ok( $xlog_dir, 'eq' , $shipper->xlog_dir(), "Same dirs first and second time");
            ok( my $snapshot_dir = $shipper->snapshot_dir() , "snapshot dir is defined");
            cmp_ok( $snapshot_dir, 'eq' , $shipper->snapshot_dir(), "Same dirs first and second time");
            my ($tmp_fh , $tmp_file ) = File::Temp::tempfile('aaaa_snapshot_XXXX' , TMPDIR => 1 , UNLINK => 1);
            print $tmp_fh "FILEBACKUPCONTENT\n";
            close $tmp_fh;
            lives_ok( sub{ $shipper->ship_snapshot_file($tmp_file) }, "Shipping a snapshot file works");
            dies_ok( sub{ $shipper->ship_snapshot_file($tmp_file) } , "Shipping it again fails");
            ($tmp_fh , $tmp_file ) = File::Temp::tempfile('aaaaXXXX', TMPDIR => 1 , UNLINK => 1);
            print $tmp_fh "FILELOGCONTENT\n";
            close $tmp_fh;
            lives_ok( sub{ $shipper->ship_xlog_file($tmp_file) }, "Shipping an xlog file works");
            dies_ok( sub{ $shipper->ship_xlog_file($tmp_file) } , "Shipping it again fails");

            ok( ! $shipper->xlog_has_arrived('bbrodriguez') , "Non existant file name cannot be there");
            ok( $shipper->xlog_has_arrived(basename($tmp_file)) , "Ok shipped temp file has arrived");
            ## Let us ship a few files.
            my @xlog_files = ();
            foreach my $char ( 'b' , 'c' , 'd' ) {
              my ($fh , $fname) = File::Temp::tempfile('aaa'.$char.'XXXX' , TMPDIR => 1 , UNLINK => 1);
              push @xlog_files , $fname;
              print $fh "This is content for file $char\n";
              close $fh;

              lives_ok( sub{ $shipper->ship_snapshot_file($fname) }, "Shipping snapshot $fname works");
              dies_ok( sub{ $shipper->ship_snapshot_file($fname) } , "Shipping it again fails");

              lives_ok( sub{ $shipper->ship_xlog_file($fname) }, "Shipping xlog $fname works");
              dies_ok( sub{ $shipper->ship_xlog_file($fname) } , "Shipping it again fails");
              ok( $shipper->xlog_has_arrived(basename($fname)) , "Ok shipped temp file has arrived");
            }

            ## Cleanup all before basename of the second snapshot file
            lives_ok(sub{ $shipper->clean_archives_youngerthan(basename($xlog_files[1])); } , "Cleaning snapshot files lives");

            ## Cleanup all before basename of the second xlog_file
            lives_ok(sub{ $shipper->clean_xlogs_youngerthan(basename($xlog_files[1])); } , "Cleaning xlog files lives");
            ## Check the correct files have disappeared.
            ok( ! $shipper->xlog_has_arrived(basename($tmp_file)) , "Ok first temp file $tmp_file is not there anymore");
            ok( ! $shipper->xlog_has_arrived(basename($xlog_files[0])) , "Ok first other file is not there.");
            ok( $shipper->xlog_has_arrived(basename($xlog_files[1])) , "Ok second other file is still there.");
            ok( $shipper->xlog_has_arrived(basename($xlog_files[2])) , "Ok third  other file is still there.");
          }
         }

);

File::Temp::cleanup();
ok(1 , "Void test");
done_testing();
