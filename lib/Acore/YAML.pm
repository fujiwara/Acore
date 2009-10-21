package Acore::YAML;

use strict;
use warnings;
use Exporter qw/ import /;
our @EXPORT = qw/ Dump Load DumpFile LoadFile /;
our $Class;

BEGIN {
    eval "use YAML::XS"; ## no critic
    if (!$@) {
        *Dump = \&YAML::XS::Dump;
        *Load = \&YAML::XS::Load;
        *DumpFile = \&YAML::XS::DumpFile;
        *LoadFile = \&YAML::XS::LoadFile;
        $Class = "YAML::XS";
    }
    elsif ( eval "use YAML::Tiny" ) { ## no critic
        *Dump = \&YAML::Tiny::Dump;
        *Load = \&YAML::Tiny::Load;
        *DumpFile = \&YAML::Tiny::DumpFile;
        *LoadFile = \&YAML::Tiny::LoadFile;
        $Class = "YAML::Tiny";
    }
    else {
        require YAML;
        *Dump = \&YAML::Dump;
        *Load = \&YAML::Load;
        *DumpFile = \&YAML::DumpFile;
        *LoadFile = \&YAML::LoadFile;
        $Class = "YAML";
    }
};

sub class { $Class }

1;

