package Acore::WAF::ConfigLoader;

use strict;
use warnings;
use Any::Moose;
use Carp;
use Path::Class qw/ file dir /;

has cache_dir => (
    is => "rw",
);

has from => (
    is      => "rw",
    default => sub { +{} },
);

sub load {
    my $self = shift;
    my @file = @_;

    my $config = {};
    for my $file (@file) {
        next unless $file;
        $config = { %$config, %{ $self->_load_file($file) } };
    }
    return $config;
}

sub _load_file {
    my $self      = shift;
    my $file = shift;
    $file = file($file) unless ref $file;

    if ($file =~ /\.pl$/) {
        $self->from->{$file} = "pl. no cache";
        return do $file;
    }

    require Storable;    Storable->import;
    require Acore::YAML; Acore::YAML->import;

    my $config;
    my $dir = $self->cache_dir;
    if ($dir) {
        my $cache_file = dir($dir)->file( $file->basename . ".cache" );
        if (   $cache_file->stat
            && $cache_file->stat->mtime >= $file->stat->mtime
        ) {
            $config = eval { Storable::retrieve("$cache_file"); };
            if ($@ || ref $config ne "HASH") {
                carp("Can't load config cache file $cache_file : $@");
            }
            else {
                $self->from->{$file} = "cache.";
                return $config;
            }
        }
        $config = LoadFile($file);

        eval {
            Storable::nstore($config, "$cache_file");
        };
        if ($@) {
            carp("Can't open config cache file $cache_file to write: $!");
            $self->from->{$file} = "file. no cache";
            return $config;
        }
        $self->from->{$file} = "file. cache created";
    }
    else {
        $config = LoadFile($file);
        $self->from->{$file} = "file. no cache";
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
 $config = $loader->load("config.pl", "local_config.pl");
 $config = $loader->load("config.yaml", "local_config.yaml");

=head1 DESCRIPTION

YAML / .pl file loader with cache.

=head1 ATTRIBUTES

=over 4

=item cache_dir

Directory for store cache file. (default: no cache)

=item from

Loading statuses hash ref.

 $loader->load('foo.yaml', 'bar.yaml');
 $loader->from;   #= { "foo.yaml" => STATUS, "bar.yaml" => STATUS };

 # STATUS
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
