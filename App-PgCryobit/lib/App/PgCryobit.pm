package App::PgCryobit;

use Moose;
use Config::General;

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

sub _build_configuration{
    my ($self) = @_;
    my %configuration;
    foreach my $path ( @{$self->config_paths()} ){
	if( -f $path && -r $path ){
	    %configuration = Config::General::ParseConfig($path);
	    return \%configuration;
	}
	if( -d $path && -r $path.'/pg_cryobit.conf' ){
	    %configuration = Config::General::ParseConfig($path.'/pg_cryobit.conf');
	    return \%configuration;
	}
    }
    die "No pg_cryobit.conf could be found in paths ".join(':',@{$self->config_paths()}); 
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
