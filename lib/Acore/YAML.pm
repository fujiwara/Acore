package Acore::YAML;

use strict;
use warnings;
use Exporter qw/ import /;
our @EXPORT = qw/ Dump Load DumpFile LoadFile /;
our $Class;
our $Dve;

BEGIN {
    eval "use YAML::XS()"; ## no critic
    if (!$@) {
        require Data::Visitor::Encode;
        $Dve      = Data::Visitor::Encode->new;
        *Dump     = \&_Dump;
        *Load     = \&_Load;
        *DumpFile = \&_DumpFile;
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
    Encode::decode_utf8( YAML::XS::Dump(@_) );
}

sub _Load {
    my $yaml = shift;
    $Dve->decode_utf8(
        YAML::XS::Load( Encode::encode_utf8($yaml) )
    );
}

sub _DumpFile {
    my $path = shift;
    YAML::XS::DumpFile( $path, map { $Dve->encode_utf8($_) } @_ );
}

1;

