package Acore::WAF::Plugin::Cache;

use strict;
use warnings;
use Carp 'croak';
use Any::Moose '::Role';

has cache => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        my $c           = shift;
        my $config      = $c->config->{cache};
        my $cache_class = $config->{class};
        $cache_class->require or croak("Can't require $cache_class. $@");
        $cache_class->new($config->{args});
    },
);

1;
__END__

=head1 NAME

Acore::WAF::Plugin::Cache - AnyCMS cache plugin

=head1 SYNOPSIS

 YourApp->setup(qw/ Cache /);
 $config->{cache} = {
     class => "Cache::Memcached",
     args  => {
         servers => ["127.0.0.1:11211"],
     },
 };

 package YourApp::Controller;
 sub foo {
     my ($self, $c) = @_;
     $c->cache->get('foo');
     $c->cache->set('foo' => 'bar');
 }

=head1 DESCRIPTION

Acore cache plugin

=head1 EXPORT METHODS

=over 4

=item cache

An instance of $config->{cache}->{class}.

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

Cache, Cache::Memcached, Cache::Memcached::Fast

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
