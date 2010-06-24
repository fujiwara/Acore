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

my $yaml = "t/tmp/test_config.yaml";
YAML::DumpFile(
    $yaml => {
        name => "TestApp",
        foo  => "foo",
    }
);
my $local = "t/tmp/test_config_local.yaml";
YAML::DumpFile(
    $local => {
        foo  => "FOO",
        baz  => "BAZ",
    }
);

{
    my $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp", foo => "foo" } );
    is $loader->from->{$yaml} => "file. no cache";
}

{
    my $config = $loader->load($yaml, $local);
    is_deeply( $config => { name => "TestApp", foo => "FOO", baz => "BAZ" } );
    is $loader->from->{$yaml}  => "file. no cache";
    is $loader->from->{$local} => "file. no cache";
}

{
    my $config = $loader->load($yaml, $local, undef);
    is_deeply( $config => { name => "TestApp", foo => "FOO", baz => "BAZ" } );
    is $loader->from->{$yaml}  => "file. no cache";
    is $loader->from->{$local} => "file. no cache";
}

{
    my $config = $loader->load($yaml, undef, $local);
    is_deeply( $config => { name => "TestApp", foo => "FOO", baz => "BAZ" } );
    is $loader->from->{$yaml}  => "file. no cache";
    is $loader->from->{$local} => "file. no cache";
}

{
    $loader->cache_dir("t/tmp");
    my $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp", foo => "foo" } );
    ok -e "t/tmp/test_config.yaml.cache";
    is $loader->from->{$yaml} => "file. cache created";

    $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp", foo => "foo" } );
    is $loader->from->{$yaml} => "cache.";

    unlink "t/tmp/test_config.yaml.cache";
    $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp", foo => "foo" } );
    is $loader->from->{$yaml} => "file. cache created";

    unlink "t/tmp/test_config.yaml.cache";
    $loader->cache_dir(undef);
    $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp", foo => "foo" } );
    is $loader->from->{$yaml} => "file. no cache";
}


{
    $loader->cache_dir("t/tmp");
    my $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp", foo => "foo" } );
    ok -e "t/tmp/test_config.yaml.cache";
    is $loader->from->{$yaml} => "file. cache created";

    # break cache
    {
        my $fh = file("t/tmp/test_config.yaml.cache")->open(">");
        $fh->print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
    }
    $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp", foo => "foo" } );
    is $loader->from->{$yaml} => "file. cache created";
}

{
    $loader->cache_dir("t/notfound");
    my $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp", foo => "foo" } );
    is $loader->from->{$yaml} => "file. no cache";
}


unlink "t/tmp/test_config.yaml";
unlink "t/tmp/test_config_local.yaml";

done_testing;
