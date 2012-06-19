package App::PgCryobit::ShipperFactory::MultiFactory;
use Moose;
extends qw/App::PgCryobit::ShipperFactory/;

use App::PgCryobit::Shipper::MultiShipper;

=head2 build_shipper

This will return a MultiShipper

=cut

sub build_shipper{
    my ($self) = @_;
    my $shippers = $self->config()->{shipper};
    unless( $shippers ){
      die "Missing shipper(s) in MultiShipper configuration\n";
    }
    ## In case there is only one shipper, it's
    ## a straigh hash in the config format.
    if( ref( $shippers ) eq 'HASH' ){
      $shippers = [ $shippers ];
    }
    unless( ref($shippers) eq 'ARRAY' ){
      die "Bad shipper array";
    }

    my @shippers = ();

    my $count = 0;
    foreach my $shipper_hash ( @$shippers ){
      $count++;
      my $factory_class = $shipper_hash->{plugin};
      unless( $factory_class ){
        die "Missing 'plugin' parameter for shipper configuration # $count\n";
      }
      $factory_class = $self->app()->load_factory_class($factory_class);
      push @shippers , $factory_class->new({ config => $shipper_hash , app => $self->app() })->build_shipper();
    }

    return App::PgCryobit::Shipper::MultiShipper->new( { shippers => \@shippers } ) ;
}

1;
