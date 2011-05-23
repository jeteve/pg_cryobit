package App::PgCryobit::Shipper::FTPShipper;
use Moose;
extends qw/App::PgCryobit::Shipper/;

use Net::FTP;
use File::Basename;

## Ftp server config
has 'ftp_host' => ( is => 'ro' , isa => 'Str' , required => 1 );
has 'ftp_port' => ( is => 'ro' , isa => 'Int' , required => 1 , default => 21 );
has 'ftp_user'   => ( is => 'ro' , isa => 'Str' , required => 1 );
has 'ftp_password' => ( is => 'ro' , isa => 'Str', required => 1 );

## The destination directory in the ftp server
has 'backup_dir' => ( is => 'ro' , isa => 'Str' , required => 1 );

has 'net_ftp' => ( is => 'ro' , isa => 'Net::FTP' , lazy_build => 1);

=head1 NAME

App::PgCryobit::Shipper::FTPShipper - A Shipper to ship the backup files via FTP.

=head1 CONFIGURATION

ftp_host - The address of the FTP server to connect to

ftp_user - The user to connect as

ftp_password - The password to use on connection.

backup_dir - The directory inside the ftp server where to manage the files shipping. MUST exist.


=cut

has 'xlog_dir' => ( is => 'ro' , isa => 'Str' , lazy_build => 1 );
has 'snapshot_dir' => ( is => 'ro', isa => 'Str', lazy_build => 1);

## Return a connected ftp
sub _build_net_ftp{
  my ($self) = @_;
  my $ftp = Net::FTP->new($self->ftp_host() , Port => $self->ftp_port() ) or
    die "Cannot connect to '".$self->ftp_host.":".$self->ftp_port()."' : $@ \n";
  $ftp->login($self->ftp_user() , $self->ftp_password())
    or die "ftp_session: Cannot login as ".$self->ftp_user().":".$ftp->message;
  return $ftp;
}

sub _ftp_session{
  my ($self , $sub ) = @_;
  my $ftp = $self->net_ftp();
  my $ret;
  eval{
    $ret = &{$sub}($ftp);
  };
  my $err = $@;
  if ( $err ) {
    die "ERROR in ftp_session: $err";
  }
  return $ret;
}

sub _ensure_subdir{
  my ($self , $dir ) = @_;
  my $sub_dir = $self->backup_dir().'/'.$dir;
  my $do_stuff =
    sub{
        my $ftp = shift;
        ## We always issue a mkdir command.
        ## It is harmful if the directory exists.
        my $new_dir = $ftp->mkdir($sub_dir , 'RECURSE') or die "Cannot create $sub_dir";
        return $sub_dir;
       };
  return $self->_ftp_session($do_stuff);
}

sub _build_xlog_dir{
  my ($self) = @_;
  return $self->_ensure_subdir('xlog');
}

sub _build_snapshot_dir{
  my ($self) = @_;
  return $self->_ensure_subdir('snapshots');
}

=head2 check_config

See L<App::PgCryobit::Shipper>

=cut

sub check_config{
  my ($self) = @_;

  ## Check we can connect to the ftp server.
  my $ftp = $self->net_ftp();

  ## Check we can change to the remote root server.
  $ftp->cwd($self->backup_dir())
    or die "Cannot change to ".$self->backup_dir.":".$ftp->message."\n";

  ## We are connected and in the right directory
  ## Check we can write and destroy some ping dir
  $ftp->mkdir('check_config_test')
    or die "Cannot make test directory :".$ftp->message."\n";

  $ftp->rmdir('check_config_test')
    or die "Cannot destroy test directory :".$ftp->message."\n";

  unless ( $self->xlog_dir() ) {
    die "Cannot make xlog_dir";
  }

  unless ( $self->snapshot_dir() ) {
    die "Cannot make snapshot_dir";
  }

  return 0;
}


sub _ship_file{
  my ($self , $file , $base_dir ) = @_;
  my $basename = basename($file);
  my $destination = $base_dir.'/'.$basename;
  my $do_stuff =
    sub{
        my $ftp = shift;
        if ( $ftp->mdtm( $destination ) ) {
          die "Destination file $destination already exists for copying $file\n";
        }
        # Copy the file to the basename
        $ftp->binary();
        my $remote_name = $ftp->put($file,$destination);
        unless( $remote_name ){
          my $message = $ftp->message();
          ## Issue a delete. In case the transfer failed
                             ## in the middle.
          $ftp->delete($destination);
          die "Copy from $file to $destination failed:".$message;
        }
        return $remote_name;
       };
  return $self->_ftp_session($do_stuff);
}

=head2 ship_xlog_file

See L<App::PgCryobit::Shipper>

=cut

sub ship_xlog_file{
                   my ($self, $file ) = @_;
                   return $self->_ship_file($file , $self->xlog_dir);
}


=head2 ship_snapshot_file

See L<App::PgCryobit::Shipper>

=cut

sub ship_snapshot_file{
                       my ($self, $file) = @_;
                       return $self->_ship_file($file , $self->snapshot_dir);
}


=head2 xlog_has_arrived

See L<App::PgCryobit::Shipper>

=cut

sub xlog_has_arrived{
  my ($self, $xlog_file) = @_;
  my $do_stuff =
    sub{
        my $ftp = shift;
        if ( $ftp->mdtm( $self->xlog_dir().'/'.$xlog_file  ) ) {
          return 1;
        }
        return 0;
       };
  return $self->_ftp_session($do_stuff);
}

sub _clean_files_youngerthan{
  my ($self , $file , $base_dir ) = @_;
  my $do_stuff =
    sub{
        my $ftp = shift;
        ## List files in basedir
        my $list = $ftp->ls($base_dir) or die "Cannot list $base_dir on ".$self->ftp_host.' : '.$ftp->message();
        foreach my $candidate ( @{$list} ) {
          if ( $candidate =~ /\.$/ ) {
            ## skip anything ending with a .
            next;
          }
          if ( basename($candidate) lt $file ) {
            $ftp->delete($base_dir.'/'.$candidate) or die "Cannot delete $base_dir/$candidate:".$ftp->message();
          }
        }
       };
  return $self->_ftp_session($do_stuff);
}

=head2 clean_xlogs_youngerthan

See L<App::PgCryobit::Shipper>

=cut

sub clean_xlogs_youngerthan{
  my ($self, $file) = @_;
  return $self->_clean_files_youngerthan($file , $self->xlog_dir);
}

=head2 clean_archives_youngerthan

See L<App::PgCryobit::Shipper>

=cut

sub clean_archives_youngerthan{
  my ($self, $file) = @_;
  return $self->_clean_files_youngerthan($file, $self->snapshot_dir());
}


1;
