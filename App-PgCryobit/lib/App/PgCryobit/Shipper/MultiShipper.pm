package App::PgCryobit::Shipper::MultiShipper;
use Moose;
use Log::Log4perl;
extends qw/App::PgCryobit::Shipper/;

use File::Copy;
use File::Basename;

has 'shippers' => ( is => 'ro' , isa => 'ArrayRef[App::PgCryobit::Shipper]' , required => 1 , default => sub{ []; } );
## Holds the crippled shippers.
has 'crippled' => ( is => 'ro' , isa => 'HashRef[App::PgCryobit::Shipper]' , required => 1 , default => sub{ {}; } );

my $LOGGER = Log::Log4perl->get_logger();

=head1 NAME

App::PgCryobit::Shipper::MultiShipper - A shipper for composing from other shippers.

=cut

=head2 check_config

See L<App::PgCryobit::Shipper>

Distributes the checkconfig to the subshippers.

=cut

sub check_config{
    my ($self) = @_;

    my $err = 0;
    foreach my $shipper ( @{$self->shippers()} ){
      $LOGGER->debug("Checking sub shipper".$shipper);
      $shipper->check_config();
    }
    return 0;
}

sub _valid_shippers{
  my ($self) = @_;
  my @shippers = @{$self->shippers()};
  my @valid = ();
  foreach my $candidate ( @shippers ){
    unless( $self->crippled()->{$candidate} ){
      push @valid, $candidate;
    }else{
      $LOGGER->warn("Not using shipper $candidate as it failed in this process");
    }
  }
  unless( @valid ){
    die "No valid shippers in $self anymore";
  }
  return @valid;
}

sub _cripple_shipper{
  my ($self, $shipper) = @_;
  $LOGGER->info("Marking $shipper as Crippled. Will not use it for the rest of this process");
  $self->crippled()->{$shipper.''} = $shipper;
}


=head2 ship_xlog_file

See L<App::PgCryobit::Shipper>

=cut

sub ship_xlog_file{
    my ($self , $file) = @_;
    $LOGGER->info("Multi shipping xlog file $file");
    my $success = 0;
    foreach my $shipper ( $self->_valid_shippers() ){
      eval{ $shipper->ship_xlog_file($file); };
      if( my $err = $@ ){
        $LOGGER->warn(qq|Shipper $shipper has failed to ship the file: $err|);
        $self->_cripple_shipper($shipper);
      }else{
        $success++;
      }
    }
    unless( $success ){
      die "Could not ship xlog $file successfully with any shipper";
    }
}

=head2 ship_snapshot_file

See L<App::PgCryobit::Shipper>

=cut

sub ship_snapshot_file{
  my ($self, $file) = @_;
  $LOGGER->info("Multi shipping snapshot file $file");
  my $success = 0;
  foreach my $shipper ( $self->_valid_shippers() ){
    eval{ $shipper->ship_snapshot_file($file); };
    if( my $err = $@ ){
      $LOGGER->warn(qq|Shipper $shipper has failed to ship the file: $err|);
      $self->_cripple_shipper($shipper);
    }else{
      $success++;
    }
  }
  unless( $success ){
    die "Could not ship xlog $file successfully with any shipper";
  }
}

=head2 xlog_has_arrived

See L<App::PgCryobit::Shipper>

Returns true if the given file has arrived via AT LEAST ONE of the shippers.

This makes multishippers more reliable, which is the goal.

=cut

sub xlog_has_arrived{
    my ($self, $xlog_file) = @_;

    foreach my $shipper ( $self->_valid_shippers() ){
      if( $shipper->xlog_has_arrived($xlog_file) ){
        return 1;
      }
    }
    return 0;
}

=head2 clean_xlogs_youngerthan

See L<App::PgCryobit::Shipper>

Dispatches the request to the valid shippers. Just warns in case of errors.

=cut

sub clean_xlogs_youngerthan{
  my ($self, $file) = @_;
  foreach my $shipper ( $self->_valid_shippers() ){
    eval{ $shipper->clean_xlogs_youngerthan($file) ;};
    if( my $err = $@ ){
      $LOGGER->warn("Failed to clean xlogs younger thant $file with $shipper: $err");
    }
  }
}

=head2 clean_archives_youngerthan

See L<App::PgCryobit::Shipper>

Dispatches the cleanup query.

=cut

sub clean_archives_youngerthan{
  my ($self, $file) = @_;
  foreach my $shipper ( $self->_valid_shippers() ){
    eval{ $shipper->clean_archives_youngerthan($file) ;};
    if( my $err = $@ ){
      $LOGGER->warn("Failed to clean archives younger thant $file with $shipper: $err");
    }
  }
}


__PACKAGE__->meta->make_immutable();
