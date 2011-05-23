#!perl -w

use Test::More;
use Test::Exception;

use App::PgCryobit::ShipperFactory::CopyFactory;
use App::PgCryobit::ShipperFactory::FTPFactory;

my %CONFIGS = (
               'App::PgCryobit::ShipperFactory::CopyFactory' => { backup_dir => '/nonexisting/' },
               'App::PgCryobit::ShipperFactory::FTPFactory' => { backup_dir => '/nonexisting',
                                                                 ftp_host => 'a.fake.host',
                                                                 ftp_user => 'USER',
                                                                 ftp_password => 'PASSWORD',
                                                               }
              );

foreach my $fact_class ( sort keys %CONFIGS ){
  ok( my $factory = $fact_class->new( { config => $CONFIGS{$fact_class}  } ), "Can create factory $fact_class" );
  lives_ok( sub{ my $shipper = $factory->build_shipper() ; } , "Can build shipper with $factory");
}

{
  ## Test ftp_port param

  my $config  = { backup_dir => '/nonexisting',
                  ftp_host => 'a.fake.host',
                  ftp_user => 'USER',
                  ftp_password => 'PASSWORD',
                  ftp_port => 'abcd'
                };

  ok( my $f = App::PgCryobit::ShipperFactory::FTPFactory->new({ config => $config  }) , "Ok new");
  dies_ok( sub{ my $shipper = $f->build_shipper() ; } , "Cannot build shipper with invalid port");
  $config->{'ftp_port'} = 222222;
  lives_ok( sub{ my $shipper = $f->build_shipper() ; } , "Can build shipper with valid port");
}

ok(1 , "Void test");
done_testing();
