package Acore::WAF::ConfigLoader;

use strict;
use warnings;
use Any::Moose;
use Carp;
use Path::Class qw/ file dir /;
use Storable;

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
        my $cache_file = dir($dir)->file( $yaml_file->basename . ".cache" );
        if (   $cache_file->stat
            && $cache_file->stat->mtime >= $yaml_file->stat->mtime
        ) {
            $config = eval { Storable::retrieve("$cache_file"); };
            if ($@ || ref $config ne "HASH") {
                carp("Can't load config cache file $cache_file : $@");
            }
            else {
                $self->from("cache.");
                return $config;
            }
        }
        require YAML;
        $config = YAML::LoadFile($yaml_file);

        eval {
            Storable::nstore($config, "$cache_file");
        };
        if ($@) {
            carp("Can't open config cache file $cache_file to write: $!");
            $self->from("file. no cache");
            return $config;
        }
        $self->from("file. cache created");
    }
    else {
        require YAML;
        $config = YAML::LoadFile($yaml_file);
        $self->from("file. no cache");
    }
    return $config;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
__END__

=head1 NAME

Acore::WAF::ConfigLoader - AnyCMS config file loader

=head1 SYNOPSIS

 $loader = Acore::WAF::ConfigLoader->new;
 $loader->cache_dir("/path/to/cach");
 $config = $loader->load("config.yaml");

=head1 DESCRIPTION

YAML file loader with cache.

=head1 ATTRIBUTES

=over 4

=item cache_dir

Directory for store cache file. (default: no cache)

=item from

Loading status.

 "file. cache created"
 "file. no cache"
 "cache."

=back

=head1 METHODS

=over 4

=item load

Load yaml file.

if $loader->cache_dir exists, create cache file.

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

YAML

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
