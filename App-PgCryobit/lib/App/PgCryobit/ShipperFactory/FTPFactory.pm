package App::PgCryobit::ShipperFactory::FTPFactory;
use Moose;
extends qw/App::PgCryobit::ShipperFactory/;

use App::PgCryobit::Shipper::FTPShipper;

=head2 build_shipper

This will return a CopyShipper

=cut

sub build_shipper{
    my ($self) = @_;

    my @required = qw/ftp_host ftp_user ftp_password backup_dir/;
    foreach my $req ( @required ){
      unless( $self->config()->{$req} ){
        die "App::PgCryobit::ShipperFactory::FTPFactory - Missing $req in configuration\n";
      }
    }

    my $args = { backup_dir => $self->config()->{backup_dir},
                 ftp_host => $self->config()->{ftp_host},
                 ftp_user => $self->config()->{ftp_user},
                 ftp_password => $self->config()->{ftp_password}
               };
    if( my $port = $self->config()->{ftp_port} ){
      unless( $port =~ /^\d+$/ ){
        die "App::PgCryobit::ShipperFactory::FTPFactory - ftp_port have to be numerical. It is not:$port\n";
      }
      $args->{ftp_port} = $port;
    }

    return App::PgCryobit::Shipper::FTPShipper->new( $args ) ;
}

1;
