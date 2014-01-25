use inc::Module::Install;

name     'App-PgCryobit';
all_from 'lib/App/PgCryobit.pm';
install_script 'pg_cryobit';
author   q{Jerome Eteve <jerome@eteve.net>};
license  'perl';

requires 'Moose' => 0.94;
requires 'Config::General' => 2.44;
requires 'Class::Load' => 0.20;
requires 'DBD::Pg' => '2.16.1';
requires 'Pod::Usage' => 1.35;
requires 'Getopt::Long' => 2.37;
requires 'File::Copy' => 2.11;
requires 'File::Basename' => 2.76;
requires 'File::Temp';
requires 'Net::FTP' => 2.77;
requires 'Log::Log4perl' => 1.29;
requires 'Data::UUID' =>  1.0602;


## This module is to be used only on a PostgreSQL fitted box
requires_external_bin 'pg_ctlcluster';
requires_external_bin 'tar';

build_requires 'Test::More';
build_requires 'Test::Exception';
build_requires 'File::Spec';
auto_install;

WriteAll;
