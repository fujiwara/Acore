package Acore::LoadModules;

use strict;
use warnings;
use Acore;
use Path::Class qw/ dir file /;
use DBIx::CouchLike;
use Data::Dumper;
use Acore::DocumentLoader;
use Acore::WAF::ConfigLoader;
use Acore::WAF::Log;
use Plack::Request;
eval { require Senna };

do {
    my $root = $INC{'Acore.pm'};
    $root =~ s/\.pm$//;
    my $dir = dir($root);
    my %modules;
    $dir->recurse(
        callback => sub {
            my $file = shift;
            return if $file->is_dir;
            return if $file !~ /\.pm$/ || $file =~ /\.svn|\.git/;
            my $source = $file->slurp;
            my @modules
                = ( $source =~ m{[^>]require\s+([a-zA-Z0-9_:]+);}g );
            for my $m (@modules) {
                $modules{ $m } = 1;
            }
        }
    );
    my $code = map { "use $_();" } sort keys %modules;
    eval $code; ## no critic;
    if ($@) {
        die $@;
    }
};

1;
