# -*- mode:perl -*-
use strict;
use warnings;
use Test::More;
use YAML;
use Test::Exception;
use Path::Class qw/ file /;

use_ok('Acore::WAF::ConfigLoader');

my $loader = Acore::WAF::ConfigLoader->new;
isa_ok $loader => "Acore::WAF::ConfigLoader";
can_ok $loader, qw/ new load cache_dir /;

my $pl = "t/tmp/test_config.pl";
file($pl)->openw->print(q|
+{
    name => "TestApp",
    foo  => "foo",
};
|);
my $local = "t/tmp/test_config_local.pl";
file($local)->openw->print(q|
+{
    foo  => "FOO",
    baz  => "BAZ",
};
|);

{
    my $config = $loader->load($pl);
    is_deeply( $config => { name => "TestApp", foo => "foo" } );
    is $loader->from->{$pl} => "pl. no cache";
}

{
    my $config = $loader->load($pl, $local);
    is_deeply( $config => { name => "TestApp", foo => "FOO", baz => "BAZ" } );
    is $loader->from->{$pl}    => "pl. no cache";
    is $loader->from->{$local} => "pl. no cache";
}

{
    my $config = $loader->load($pl, $local, undef);
    is_deeply( $config => { name => "TestApp", foo => "FOO", baz => "BAZ" } );
    is $loader->from->{$pl}    => "pl. no cache";
    is $loader->from->{$local} => "pl. no cache";
}

{
    my $config = $loader->load($pl, undef, $local);
    is_deeply( $config => { name => "TestApp", foo => "FOO", baz => "BAZ" } );
    is $loader->from->{$pl}    => "pl. no cache";
    is $loader->from->{$local} => "pl. no cache";
}

unlink "t/tmp/test_config.pl";
unlink "t/tmp/test_config_local.pl";

done_testing;
