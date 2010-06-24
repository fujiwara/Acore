package Acore::YAML;

use strict;
use warnings;
use Encode   qw/ encode_utf8 decode_utf8 /;
use Exporter qw/ import /;

our @EXPORT = qw/ Dump Load DumpFile LoadFile /;
our $Class;

BEGIN {

    eval "use YAML::XS()"; ## no critic
    if (!$@) {
        *Dump     = \&_Dump;
        *Load     = \&_Load;
        *DumpFile = \&YAML::XS::DumpFile;
        *LoadFile = \&YAML::XS::LoadFile;
        return $Class = "YAML::XS";
    }

    require YAML;
    *Dump     = \&YAML::Dump;
    *Load     = \&YAML::Load;
    *DumpFile = \&YAML::DumpFile;
    *LoadFile = \&YAML::LoadFile;
    $Class = "YAML";
};

sub class { $Class }

sub _Dump {
    decode_utf8( YAML::XS::Dump(@_) );
}

sub _Load {
    YAML::XS::Load( encode_utf8 $_[0] )
}

1;
