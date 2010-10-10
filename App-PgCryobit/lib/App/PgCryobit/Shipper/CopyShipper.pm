package App::PgCryobit::Shipper::CopyShipper;
use Moose;
extends qw/App::PgCryobit::Shipper/;

use File::Copy;
use File::Basename;

has 'backup_dir' => ( is => 'ro' , isa => 'Str' , required => 1 );
has 'xlog_dir' => ( is => 'ro' , isa => 'Str' , lazy_build => 1 );
has 'snapshot_dir' => ( is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_xlog_dir{
    my ($self) = @_;
    $self->check_config();

    my $xlog_dir = $self->backup_dir().'/xlogs';
    if( -d $xlog_dir ){
	return $xlog_dir;
    }
    if ( mkdir $xlog_dir ){
	return $xlog_dir;
    }
    die "Cannot create $xlog_dir for $self\n";
}

sub _build_snapshot_dir{
    my ($self) = @_;
    $self->check_config();

    my $snapshot_dir = $self->backup_dir().'/snapshots';
    if( -d $snapshot_dir ){
	return $snapshot_dir;
    }
    if ( mkdir $snapshot_dir ){
	return $snapshot_dir;
    }
    die "Cannot create $snapshot_dir for $self\n";
}

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

=head2 ship_xlog_file

See L<App::PgCryobit::Shipper>

=cut

sub ship_xlog_file{
    my ($self , $file) = @_;
    
    my $basename = basename($file);
    my $destination = $self->xlog_dir().'/'.$basename;
    if ( -f $destination ){
	die "Destination file $destination already exists for copying $file\n";
    }
    # Copy the file to the basename
    copy($file,$self->xlog_dir().'/'.$basename) or die "Copy from $file to $destination failed: $!\n";
}

=head2 ship_snapshot_file

See L<App::PgCryobit::Shipper>

=cut

sub ship_snapshot_file{
    my ($self, $file) = @_;
    my $basename = basename($file);
    my $destination = $self->snapshot_dir().'/'.$basename;
    if ( -f $destination ){
	die "Destination file $destination already exists for copying $file\n";
    }
    # Copy the file to the basename
    copy($file,$destination) or die "Copy from $file to $destination failed: $!\n";
}

=head2 xlog_has_arrived

See L<App::PgCryobit::Shipper>

=cut

sub xlog_has_arrived{
    my ($self, $xlog_file) = @_;
    if( -f $self->xlog_dir().'/'.$xlog_file ){
	return 1;
    }
    return 0;
}

=head2 clean_xlogs_youngerthan

See L<App::PgCryobit::Shipper>

=cut

sub clean_xlogs_youngerthan{
    my ($self, $file) = @_;
    my @candidates = glob $self->xlog_dir().'/*';
    foreach my $candidate ( @candidates ){
	if ( basename($candidate) lt $file ){
	    unlink $candidate or die "Cannot remove $candidate: $!\n";
	}
    }
}

=head2 clean_archives_youngerthan

See L<App::PgCryobit::Shipper>

=cut

sub clean_archives_youngerthan{
    my ($self, $file) = @_;
    my @candidates = glob $self->snapshot_dir().'/*';
    foreach my $candidate ( @candidates ){
	if ( basename($candidate) lt $file ){
	    unlink $candidate or die "Cannot remove $candidate: $!\n";
	}
    }
}


1;
