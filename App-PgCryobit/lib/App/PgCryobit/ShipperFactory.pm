package App::PgCryobit::ShipperFactory;
use Moose;

=head1 NAME

App::PgCryobit::ShipperFactory - Base virtual class for a shipper factory.

=head1 SYNOPSYS

my $factory = $factory_class->new( { config => \%factory_config } );
my $shipper = $factory->build_shipper();

=cut

has 'config' => ( is => 'ro' , isa => 'HashRef' , required => 1);

=head2 build_shipper

Builds a L<App::PgCryobit::Shipper> with this factory.

=cut

sub build_shipper{
    my ($self) = @_;
    die "Please implement build_shipper on $self\n";
}

1;
