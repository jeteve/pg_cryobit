use inc::Module::Install;

name     'App-PgCryobit';
all_from 'lib/App/PgCryobit.pm';
install_script 'pg_cryobit';
author   q{Jerome Eteve <jerome@eteve.net>};
license  'perl';

requires 'Moose' => 0.94;
requires 'Config::General' => 2.44;
requires 'DBD::Pg' => '2.16.1';

build_requires 'Test::More';
build_requires 'Test::Exception';
build_requires 'Test::postgresql' => 0.09;

auto_install;

WriteAll;

