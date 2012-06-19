#!perl -w

use Test::More;
use Test::Exception;

use App::PgCryobit;
# use App::PgCryobit::ShipperFactory::CopyFactory;
# use App::PgCryobit::ShipperFactory::FTPFactory;
use Log::Log4perl qw/:easy/;
Log::Log4perl->easy_init($DEBUG);

my %CONFIGS = (
               'App::PgCryobit::ShipperFactory::CopyFactory' => { backup_dir => '/nonexisting/' },
               'App::PgCryobit::ShipperFactory::FTPFactory' => { backup_dir => '/nonexisting',
                                                                 ftp_host => 'a.fake.host',
                                                                 ftp_user => 'USER',
                                                                 ftp_password => 'PASSWORD',
                                                               },
               'App::PgCryobit::ShipperFactory::MultiFactory' => {
                                                                  'shipper' =>
                                                                  [{
                                                                    'plugin' => 'CopyFactory',
                                                                    'backup_dir' => '/nonexisting'
                                                                   },
                                                                   {
                                                                    'plugin' => 'App::PgCryobit::ShipperFactory::FTPFactory',
                                                                    'backup_dir' => '/nonexisting',
                                                                    ftp_host => 'a.fake.host',
                                                                    ftp_user => 'USER',
                                                                    ftp_password => 'PASSWORD'
                                                                   }
                                                                  ]
                                                                 },
              );

## Make sure we load an app with a faulty config (because we dont test it, we just need it).
my $app = App::PgCryobit->new({ config_paths => ['conf_test/pg_cryobit_faulty.conf'] });

foreach my $fact_class ( sort keys %CONFIGS ){
  ## Make sure we load this class.
  $fact_class = $app->load_factory_class($fact_class);
  ok( my $factory = $fact_class->new( { config => $CONFIGS{$fact_class} , app => $app  } ), "Can create factory $fact_class" );
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

  ok( my $f = App::PgCryobit::ShipperFactory::FTPFactory->new({ config => $config , app => $app  }) , "Ok new");
  dies_ok( sub{ my $shipper = $f->build_shipper() ; } , "Cannot build shipper with invalid port");
  $config->{'ftp_port'} = 222222;
  lives_ok( sub{ my $shipper = $f->build_shipper() ; } , "Can build shipper with valid port");
}

ok(1 , "Void test");
done_testing();
