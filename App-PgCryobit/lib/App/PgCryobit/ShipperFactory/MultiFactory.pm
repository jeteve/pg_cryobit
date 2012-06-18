package App::PgCryobit::ShipperFactory::MultiFactory;
use Moose;
extends qw/App::PgCryobit::ShipperFactory/;

use App::PgCryobit::Shipper::MultiShipper;

=head2 build_shipper

This will return a MultiShipper

=cut

sub build_shipper{
    my ($self) = @_;
    my $plugins = $self->config()->{plugins};
    unless( $plugins && ref($plugins) eq 'ARRAY' && @$plugins ){
      die "Missing array of 'plugins' in configuration\n";
    }

    my @shippers = ();

    my $count = 0;
    foreach my $plugin_hash ( @$plugins ){
      $count++;
      my $factory_class = $plugin_hash->{plugin};
      unless( $factory_class ){
        die "Missing 'plugin' parameter for plugin configuration # $count\n";
      }
      $factory_class = $self->app()->load_factory_class($factory_class);
      push @shippers , $factory_class->new({ config => $plugin_hash , app => $self->app() })->build_shipper();
    }

    return App::PgCryobit::Shipper::MultiShipper->new( { shippers => \@shippers } ) ;
}

1;
