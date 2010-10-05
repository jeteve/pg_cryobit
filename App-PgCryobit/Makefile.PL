use inc::Module::Install;

name     'App-PgCryobit';
all_from 'lib/App/PgCryobit.pm';
author   q{Jerome Eteve <jerome@eteve.net>};
license  'perl';

requires 'Moose' => 0.94;
requires 'Config::General' => 2.44;
build_requires 'Test::More';
build_requires 'Test::Exception';

auto_install;

WriteAll;

