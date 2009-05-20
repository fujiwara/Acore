package Acore::WAF::ConfigLoader;

use strict;
use warnings;
use Any::Moose;
use Carp;
use Path::Class qw/ file dir /;
use Data::Dumper;

has cache_dir => (
    is => "rw",
);

has from => (
    is => "rw",
);

sub load {
    my $self      = shift;
    my $yaml_file = shift;
    $yaml_file = file($yaml_file) unless ref $yaml_file;

    my $config;
    my $dir = $self->cache_dir;
    if ($dir) {
        my $pl_file = dir($dir)->file( $yaml_file->basename . ".pl" );
        if (   $pl_file->stat
            && $pl_file->stat->mtime >= $yaml_file->stat->mtime
        ) {
            $config = eval { require "$pl_file" }; ## no critic
            if ($@) {
                carp("Can't load config cache file $pl_file : $@");
            }
            else {
                $self->from("cache.");
                return $config;
            }
        }
        require YAML;
        $config = YAML::LoadFile($yaml_file)
            or croak("Can't load file: $yaml_file $!");
        my $fh = $pl_file->openw
            or do {
                carp("Can't open config cache file $pl_file to write: $!");
                return $config;
            };
        local $Data::Dumper::Indent = 1;
        $fh->print("my ", Data::Dumper->Dump([$config], ["config"]));
        $fh->close;
        $self->from("file. cache created");
    }
    else {
        require YAML;
        $config = YAML::LoadFile($yaml_file)
            or croak("Can't load file: $yaml_file $!");
        $self->from("file. no cache");
    }
    return $config;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
__END__
