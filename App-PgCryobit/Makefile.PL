use inc::Module::Install;

name     'App-PgCryobit';
all_from 'lib/App/PgCryobit.pm';
install_script 'pg_cryobit';
author   q{Jerome Eteve <jerome@eteve.net>};
license  'perl';

requires 'Moose' => 0.94;
requires 'Config::General' => 2.44;
requires 'DBD::Pg' => '2.16.1';
requires 'Pod::Usage' => 1.36;
requires 'Getopt::Long' => 2.38;
requires 'File::Copy' => 2.14;
requires 'File::Basename' => 2.77;
requires 'File::Temp';

## This module is to be used only on a PostgreSQL fitted box
requires_external_bin 'pg_ctlcluster';

build_requires 'Test::More';
build_requires 'Test::Exception';
build_requires 'Test::postgresql' => 0.09;
build_requires 'File::Spec';
auto_install;

WriteAll;
