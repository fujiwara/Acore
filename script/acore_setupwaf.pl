#!/usr/bin/perl
use strict;
use warnings;
use Acore::CLI::SetupWAF;
use Getopt::Long;

my ($name, $usage);
GetOptions(
    "name=s" => \$name,
    "help"   => \$usage,
)
    or die "Can't complete";

Acore::CLI::SetupWAF->run($name, $usage);

print "Done.\n";
