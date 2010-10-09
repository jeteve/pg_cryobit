package App::PgCryobit::Shipper::CopyShipper;
use Moose;
extends qw/App::PgCryobit::Shipper/;

has 'backup_dir' => ( is => 'ro' , isa => 'Str' , required => 1 );

=head1 NAME

App::PgCryobit::Shipper::CopyShipper - A Simple file copy shipper

=cut

=head2 check_config

See L<App::PgCryobit::Shipper>

=cut

sub check_config{
    my ($self) = @_;
    unless( -d $self->backup_dir() ){
	die $self->backup_dir()." is NOT a directory\n";
    }
    unless( -w $self->backup_dir() ){
	die $self->backup_dir()." is NOT writable\n";
    }
    return 0;
}


1;
