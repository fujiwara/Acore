#!/usr/bin/perl
use strict;
use warnings;
use Acore::CLI::SetupDB;
use Getopt::Long;

my ($dsn, $user, $password, $usage);
GetOptions(
    "dsn=s"      => \$dsn,
    "username=s" => \$user,
    "password=s" => \$password,
    "help"       => \$usage,
);

Acore::CLI::SetupDB->run($dsn, $user, $password, $usage)
    or die "Can't complete";
print "Done.\n";
