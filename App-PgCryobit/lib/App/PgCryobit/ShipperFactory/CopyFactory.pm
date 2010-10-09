package App::PgCryobit::ShipperFactory::CopyFactory;
use Moose;
extends qw/App::PgCryobit::ShipperFactory/;

use App::PgCryobit::Shipper::CopyShipper;

=head2 build_shipper

This will return a CopyShipper

=cut

sub build_shipper{
    my ($self) = @_;
    return App::PgCryobit::Shipper::CopyShipper->new() ;
}

1;
