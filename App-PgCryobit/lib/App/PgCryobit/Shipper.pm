package App::PgCryobit::Shipper;
use Moose;

=head1 NAME

App::PgCryobit::Shipper - A shipper base virtual class

=cut

=head2 ship_xlog_file

Copies the given log_file somewhere safe.

=cut

sub ship_xlog_file{
    my ($self, $log_file) = @_;
    die "Please implement ship_xlog_file in $self\n";
}

=head2 ship_snapshot_file

Copies the given snapshot_file somewhere safe.

=cut

sub ship_snapshot_file{
    my ($self, $snapshot_file) = @_;
    die "Please implement ship_snapshot_file in $self\n";
}


=head2 check_config

Checks this Shipper's configuration is correct.

Returns 0 if it is.

Dies if it's not.

=cut

sub check_config{
    my ($self) = @_;
    die "Please implement check_config in $self\n";
}

1;
