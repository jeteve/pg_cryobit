package App::PgCryobit::ShipperFactory::CopyFactory;
use Moose;
extends qw/App::PgCryobit::ShipperFactory/;

use App::PgCryobit::Shipper::CopyShipper;

=head2 build_shipper

This will return a CopyShipper

=cut

sub build_shipper{
    my ($self) = @_;
    unless( $self->config()->{backup_dir} ){
	die "App::PgCryobit::ShipperFactory::CopyFactory - Missing backup_dir in configuration\n";
    }
    return App::PgCryobit::Shipper::CopyShipper->new( { backup_dir => $self->config()->{backup_dir} } ) ;
}

1;
