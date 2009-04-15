#!/usr/bin/perl
use strict;
use warnings;
use Acore::CLI::SetupDB;

Acore::CLI::SetupDB->run() || die "Can't complete";
print "Done.\n";
