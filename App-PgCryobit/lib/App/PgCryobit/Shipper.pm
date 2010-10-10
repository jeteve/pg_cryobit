package App::PgCryobit::Shipper;
use Moose;

=head1 NAME

App::PgCryobit::Shipper - A shipper base virtual class

=cut

=head2 ship_xlog_file

Copies the given log_file somewhere safe.

Dies in case of failure.

=cut

sub ship_xlog_file{
    my ($self, $log_file) = @_;
    die "Please implement ship_xlog_file in $self\n";
}

=head2 xlog_has_arrived

Checks the given xlog_name has arrived at the safe destination. Return true or false.

xlog_name is NOT an absolute file name, but something like '000000010000000000000000'.

It's returned by the PostgreSQL admin function pg_xlogfile_name(location text).

See http://www.postgresql.org/docs/8.2/static/functions-admin.html

Usage:

    if ( $this0->xlog_has_arrived('000000010000000000000000') ){
    
    }

=cut

sub xlog_has_arrived{
    my ($self, $xlog_name) = @_;
    die "Please implement xlog_has_arrived in $self\n";
}

=head2 ship_snapshot_file

Copies the given snapshot_file somewhere safe.

Dies in case of failure.

=cut

sub ship_snapshot_file{
    my ($self, $snapshot_file) = @_;
    die "Please implement ship_snapshot_file in $self\n";
}

=head2 clean_xlogs_youngerthan

Removes xlogs smaller than the given filename from the safe storage.

=cut

sub clean_xlogs_youngerthan{
    my ($self, $file) = @_;
    die "Please implement clean_xlogs_youngerthan in $self\n";
}

=head2 clean_archives_youngerthan

Remove archives smaller than the given filename from the safe storage.

=cut

sub clean_archives_youngerthan{
    my ($self, $file) = @_;
    die "Please implement clean_archives_youngerthan in $self\n";
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
