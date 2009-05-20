# -*- mode:perl -*-
use strict;
use warnings;
use Test::More tests => 21;
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
    }
);

{
    my $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp" } );
    is $loader->from => "file. no cache";
}

{
    $loader->cache_dir("t/tmp");
    my $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp" } );
    ok -e "t/tmp/test_config.yaml.cache";
    is $loader->from => "file. cache created";

    $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp" } );
    is $loader->from => "cache.";

    unlink "t/tmp/test_config.yaml.cache";
    $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp" } );
    is $loader->from => "file. cache created";

    unlink "t/tmp/test_config.yaml.cache";
    $loader->cache_dir(undef);
    $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp" } );
    is $loader->from => "file. no cache";
}


{
    $loader->cache_dir("t/tmp");
    my $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp" } );
    ok -e "t/tmp/test_config.yaml.cache";
    is $loader->from => "file. cache created";

    # break cache
    {
        my $fh = file("t/tmp/test_config.yaml.cache")->open(">");
        $fh->print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
    }
    $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp" } );
    is $loader->from => "file. cache created";
}

{
    $loader->cache_dir("t/notfound");
    my $config = $loader->load($yaml);
    is_deeply( $config => { name => "TestApp" } );
    is $loader->from => "file. no cache";
}


unlink "t/tmp/test_config.yaml";

