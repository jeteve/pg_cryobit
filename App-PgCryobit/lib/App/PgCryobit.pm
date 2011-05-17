package App::PgCryobit;

use Moose;
use Config::General;
use File::Temp;
use DBI;

=head1 NAME

App::PgCryobit - The pg_cryobit application

=head1 VERSION

Version 0.02_01

=head1 SYNOPSIS

This class is effectively a serie of scripts, meant to be called
by the pg_cryobit command.

=head1 SUBROUTINES/METHODS

=cut

our $VERSION = '0.02_01';

has 'config_paths' => ( is => 'ro' , isa => 'ArrayRef', required =>  1);
has 'configuration' => ( is => 'ro' , isa => 'HashRef' , lazy_build => 1 ); 

has 'shipper' => ( is => 'ro' , isa => 'App::PgCryobit::Shipper' , lazy_build => 1);

## The command line options. The script sets these.
has 'options' => ( is => 'rw', isa => 'HashRef' , default => sub{ return {} } );
has 'config_general' => ( is => 'rw' , isa => 'Config::General' );

sub _build_configuration{
    my ($self) = @_;
    my %configuration;
    foreach my $path ( @{$self->config_paths()} ){
	if( -f $path && -r $path ){
	    $self->config_general(Config::General->new($path));
	    %configuration = $self->config_general->getall();
	    $configuration{this_file} = $path;
	    return \%configuration;
	}
	if( -d $path && -r $path.'/pg_cryobit.conf' ){
	    $self->config_general(Config::General->new($path.'/pg_cryobit.conf'));
	    %configuration = $self->config_general->getall();
	    $configuration{this_file} = $path.'/pg_cryobit.conf';
	    return \%configuration;
	}
    }
    die "No pg_cryobit.conf could be found in paths ".join(':',@{$self->config_paths()}); 
}

sub _build_shipper{
    my ($self) = @_;
    my $shipper_factory;
    my $factory_class = $self->configuration->{shipper}->{plugin};

    my $load_err;
    eval{ $shipper_factory = Class::MOP::load_class($factory_class) };
    $load_err = $@;
    unless( $shipper_factory ){
      $factory_class = 'App::PgCryobit::ShipperFactory::'.$factory_class;
      eval{ $shipper_factory = Class::MOP::load_class($factory_class) };
      $load_err = $@;
    }
    unless( $shipper_factory ){
      die "Cannot load factory plugin ".$factory_class.": $load_err.\n  * If this class is known to exists, try loading it with perl -M$factory_class\n";
    }
    return $factory_class->new( { config => $self->configuration->{shipper} } )->build_shipper();
}

=head2 feature_checkconfig

Returns 1 if this has been erroneous, so the calling script can
exit with this code.

Returns 0 if everything went fine.

=cut

sub feature_checkconfig{
    my ($self) = @_;
    
    my $conf;
    eval{
	$conf = $self->configuration();
    };
    if( $@ ){
	print STDERR $@;
	return 1;
    }

    ## Structural and functional checking.
    unless( $conf->{data_directory} ){
	print STDERR "Missing data_directory in ".$conf->{this_file}."\n";
	return 1;
    }
    ## Check this data_directory can be read
    ## This is useful for full archive
    unless(( -d $conf->{data_directory} ) && ( -r $conf->{data_directory} )){
	print STDERR "Cannot read directory ".$conf->{data_directory}." (defined in ".$conf->{this_file}.")\n";
	return 1;
    }

    if ( $conf->{snapshooting_dir} ){
      unless( ( -d $conf->{snapshooting_dir} ) && ( -w $conf->{snapshooting_dir} ) ){
	print STDERR "Cannot access ".$conf->{snapshooting_dir}." in Write mode (defined in ".$conf->{this_file}.")\n";
	return 1;
      }
    }

    unless( $conf->{dsn} ){
	print STDERR "Missing dsn in ".$conf->{this_file}."\n";
	return 1;
    }

    ## Check we can connect using the dsn
    my $dbh = DBI->connect($conf->{dsn}, undef , undef , { RaiseError => 0 , PrintError => 0 });
    unless( $dbh ){
	print STDERR "Cannot connect to ".$conf->{dsn}." defined in ".$conf->{this_file}."\n";
	return 1;
    }
    ## Check we can call some xlog administrative functions
    my ($current_xlogfile) = $dbh->selectrow_array('SELECT pg_xlogfile_name(pg_current_xlog_location())');
    unless( $current_xlogfile ){
	print STDERR "Cannot find current_xlogfile. Make sure your dsn connects to the DB as a super user in ".$conf->{this_file}."\n";
	return 1;
    }
    ## Check archive mode is ON
    my ($archive_mode) = $dbh->selectrow_array('SHOW archive_mode');
    unless( $archive_mode eq 'on' ){
	print STDERR "archive_mode is NOT 'on' in database. Please fix that\n";
	return 1;
    }
    my ($archive_command) = $dbh->selectrow_array('SHOW archive_command');
    unless( $archive_command =~ /pg_cryobit/ ){
	print STDERR "archive_command (=$archive_command) does NOT make use of pg_cryobit. Please fix that\n";
	return 1;
    }

    unless( $conf->{shipper} ){
	print STDERR "Missing shipper section in".$conf->{this_file}."\n";
	return 1;
    }
    unless( $conf->{shipper}->{plugin} ){
	print STDERR "Missing plugin class definition in shipper in ".$conf->{this_file}."\n";
	return 1;
    }

    if( my $errcode = $self->feature_checkshipper() ){ return $errcode ;}
    $dbh->disconnect();
    return 0;
}


=head2 feature_checkshipper

Perform some sanity check on the configured shipper. Returns 1 in case of failure,
0 in case of success, so you can use this to return an exit code in the calling script.

=cut

sub feature_checkshipper{
    my ($self) = @_;
    my $shipper;
    eval{ $shipper = $self->shipper(); };
    if( $@ ){
	print STDERR $@;
	return 1;
    }
    eval{
	$shipper->check_config();
    };
    if ( $@ ){
	print STDERR $@;
	return 1;
    }
    return 0;
}

=head2 feature_archivewal

Archive wal file present in options as 'file' using the defined shipper.

Returns 0 in case of success.
1 in case of failure.

See man pg_cryobit for more info.

=cut

sub feature_archivewal{
    my ($self) = @_;
    unless( $self->options()->{file} ){
	print STDERR "Missing options 'file'\n";
	return 1;
    }
    my $file = $self->options()->{file} ;
    unless( -f $file && -r $file ){
	print STDERR "Cannot read file ".$file."\n";
	return 1;
    }

    my $shipper = $self->shipper();
    eval{
	$shipper->ship_xlog_file($file);
    };
    if( $@ ){
	print STDERR "ERROR SHIPPING FILE: $@\n";
	return 1;
    }

    return 0;
}

=head2 feature_fullarchive

Composes rotatewal and archivesnapshot.

=cut

sub feature_fullarchive{
  my ($self) = @_;
  if ( my $code = $self->feature_rotatewal() ){
    return $code;
  }
  if ( my $code_snapshot = $self->feature_archivesnapshot() ){
    return $code_snapshot;
  }
  return 0;
}

=head2 feature_rotatewal

Assumes checkconfig has been called before.

Will force the rotation of a wal and wait for its shipping to complete.

=cut

sub feature_rotatewal{
    my ($self) = @_;

    my $dbh = DBI->connect($self->configuration->{dsn}, undef , undef , { RaiseError => 0 , PrintError => 0 });
    my ($archive_command) = $dbh->selectrow_array('SHOW archive_command');

    ## Perform some transactions so the forced rotation will actually rotate.
    $dbh->do('DROP TABLE IF EXISTS pg_cryobit_to_force_rotation');
    $dbh->do('CREATE TABLE pg_cryobit_to_force_rotation (id TEXT)');
    $dbh->do('INSERT INTO pg_cryobit_force_rotation(id) VALUES(\'Blablabla\')');
    $dbh->do('DROP TABLE pg_cryobit_to_force_rotation');

    my ($shipped_log) = $dbh->selectrow_array('SELECT pg_xlogfile_name(pg_switch_xlog())');
    print STDERR "PostgreSQL will attempt to ship file $shipped_log using archive_command $archive_command\n";
    $dbh->disconnect();

    ## The check that this has arrived.
    my $shipper = $self->shipper();

    my $time_spend_waiting = 0;
    sleep(1);
    while( $time_spend_waiting < 60 ){
	if( $shipper->xlog_has_arrived($shipped_log) ){
	    return 0;
	}
	sleep(10);
	$time_spend_waiting += 10;
    }

    print STDERR "File $shipped_log is not arrived after we waited for $time_spend_waiting seconds\n";
    print STDERR "Check your PostgreSQL logs\n";
    return 1;
}

=head2 feature_archivesnapshot

Performs a full archive of the PostgreSQL 'data_directory' and ships it using the shipper.

=cut

sub feature_archivesnapshot{
    my ($self) = @_;

    my $dbh = DBI->connect($self->configuration->{dsn}, undef , undef , { RaiseError => 0 , PrintError => 0 });
    my ($now) = $dbh->selectrow_array('SELECT NOW()');
    $now =~ s/\W/_/g;
    my $archive_name = $now.'.snapshot.tgz';
    my ($archive_row) = $dbh->selectrow_array('SELECT pg_xlogfile_name_offset(pg_start_backup('.$dbh->quote($archive_name).'))');
    my ($archived_wal,$archived_offset) = ( $archive_row =~ /\((\w+?),(\w+?)\)/ );
    unless( $archived_wal && $archived_offset ){
	print STDERR "Cannot parse wal and offet from $archive_row\n";
	return 1;
    }
    $archived_offset = sprintf("%08x", $archived_offset);

    my $archive_full_file;
    eval{
      # Prefix archive name with configuration 'snapshooting_dir' or current dir
      $archive_full_file = ( $self->configuration->{snapshooting_dir} || './' ).$archive_name;
      my $cmd = 'tar -czhf '.$archive_full_file.' '.$self->configuration->{data_directory};
      my $tar_ret = system($cmd);
      if( $tar_ret != 0 ){
	die "Archiving command $cmd has failed\n";
      }
    };
    if ( $@ ){
	$dbh->selectrow_array('SELECT  pg_xlogfile_name_offset( pg_stop_backup())');
	print STDERR "CRASH in building the main archive: $@\n";
	return 1;
    }
    my ($end_archived_row) = $dbh->selectrow_array('SELECT  pg_xlogfile_name_offset( pg_stop_backup())');

    my $shipper = $self->shipper();

    ## Ship the archive file
    eval{
	$shipper->ship_snapshot_file($archive_full_file);
    };
    if( $@ ){
	print STDERR "Error shipping $archive_name : $@\n";
	return 1;
    }
    ## Wait for archive_wal.archive_offset.backup to be shipped.
    my $time_spend_waiting = 0;
    sleep(1);
    while( $time_spend_waiting < 60 ){
	if( $shipper->xlog_has_arrived($archived_wal) && $shipper->xlog_has_arrived($archived_wal.'.'.$archived_offset.'.backup') ){
	    $time_spend_waiting = 0;
	    last;
	}
	sleep(10);
	$time_spend_waiting += 10;
    }
    if( $time_spend_waiting ){
	print STDERR "$archived_wal and $archived_wal.$archived_offset.backup are not shipped after $time_spend_waiting seconds\n";
	return 1;
    }

    if( $self->options()->{deepclean} ){
      print STDERR "Will perform a deep clean\n";
      ## Deepcleaning has been requested
      eval{
	print STDERR "Cleaning wal logs younger than $archived_wal\n";
	$shipper->clean_xlogs_youngerthan($archived_wal);
	print STDERR "Cleaning archives snapshots younger than $archive_name\n";
	$shipper->clean_archives_youngerthan($archive_name);
      };
      if( $@ ){
	print STDERR "Cannot perform deepclean : $@\n";
	return 1;
      }
    } ## end of if deepclean
    return 0;
}

=head1 AUTHOR

Jerome Eteve, C<< <jerome at eteve.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-pgcryobit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-PgCryobit>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::PgCryobit


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-PgCryobit>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-PgCryobit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-PgCryobit>

=item * Search CPAN

L<http://search.cpan.org/dist/App-PgCryobit/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jerome Eteve.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of App::PgCryobit
