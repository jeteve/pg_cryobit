use inc::Module::Install;

name     'App-PgCryobit';
all_from 'lib/App/PgCryobit.pm';
author   q{Jerome Eteve <jerome@eteve.net>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

