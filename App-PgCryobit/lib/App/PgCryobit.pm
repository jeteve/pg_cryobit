package App::PgCryobit;

use Moose;
use Config::General;

use DBI;

=head1 NAME

App::PgCryobit - The pg_cryobit application

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Use the pg_cryobit command to call this.

=head1 SUBROUTINES/METHODS

=cut

our $VERSION = '0.01';

has 'config_paths' => ( is => 'ro' , isa => 'ArrayRef', required =>  1);
has 'configuration' => ( is => 'ro' , isa => 'HashRef' , lazy_build => 1 ); 
## TODO: Implement the virtual class App::PgCryobit::Shipper
has 'shipper' => ( is => 'ro' , isa => 'App::PgCryobit::Shipper' , lazy_build => 1);

sub _build_configuration{
    my ($self) = @_;
    my %configuration;
    foreach my $path ( @{$self->config_paths()} ){
	if( -f $path && -r $path ){
	    %configuration = Config::General::ParseConfig($path);
	    $configuration{this_file} = $path;
	    return \%configuration;
	}
	if( -d $path && -r $path.'/pg_cryobit.conf' ){
	    %configuration = Config::General::ParseConfig($path.'/pg_cryobit.conf');
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
    eval{ $shipper_factory = Class::MOP::load_class($factory_class) };
    unless( $shipper_factory ){
	$factory_class = 'App::PgCryobit::ShipperFactory::'.$factory_class;
	eval{ $shipper_factory = Class::MOP::load_class($factory_class) };
    }
    unless( $shipper_factory ){
	die "Cannot load factory plugin ".$factory_class.".\n  * If this class is known to exists, try loading it with Perl -M$factory_class\n";
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

    unless( $conf->{shipper} ){
	print STDERR "Missing shipper section in".$conf->{this_file}."\n";
	return 1;
    }
    unless( $conf->{shipper}->{plugin} ){
	print STDERR "Missing plugin class definition in shipper in ".$conf->{this_file}."\n";
	return 1;
    }
    
    ## TODO: Check we can load that and try building the shipper.
    if( my $errcode = $self->feature_checkshipper() ){ return $errcode ;}

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
