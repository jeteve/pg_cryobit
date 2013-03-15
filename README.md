pg_cryobit README
=================

pg_cryobit allows you to set up your PostgreSQL continuous backup from a centralized point.

It can manage different wal logs and backup shipping methods via plugins.


HOW TO INSTALL AND USE:
-----------------------

# 0 - Install

If your using a debian based system, have a look there:
http://deb.perl.it/debian/cpan-deb/#q=App%3A%3APgCryobit

Or more traditionally

$ sudo cpan -i App::PgCryobit

# 1 - Write a pg_cryobit.conf configuration file.

See CONFIGURATION section for examples. Conf files can live in the current directory, your $HOME
or in /etc/.

# 2 - Amend your postgresql.conf

Make Postgresql use pg_cryobit for log shipping:

archive_mode = on
archive_command = 'pg_cryobit archivewal --file=%p'

# 3 - Restart your PostgreSQL server and test your configuration.

Note: Depending on the way you configured your pg_cryobit.conf connection string,
you might want to run pg_cryobit as the 'postgres' user.

$ pg_cryobit checkconfig

# 4 - Whenever you want to take a full snapshot of your PostgreSQL DB, use:

$ pg_cryobit archivesnapshot

And to force rotating and shipping a new WAL file:

$ pg_cryobit rotatewal

# 5 - Install a cronjob.

If you want to take a hot snapshot of your data regularly.

CONFIGURATION
-------------

The pg_cryobit repository contains configuration file examples:

https://github.com/jeteve/pg_cryobit/tree/master/App-PgCryobit/conf_example

Have a look there and file support tickets if they're not clear enough :)


HOW TO EXTEND
-------------

$ perldoc App::PgCryobit::ShipperFactory will tell you.
