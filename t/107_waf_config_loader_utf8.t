# -*- mode:perl -*-
use strict;
use warnings;
use Test::More;
use YAML;
use Test::Exception;
use Path::Class qw/ file /;
use Encode;
use utf8;

use_ok('Acore::WAF::ConfigLoader');

my $loader = Acore::WAF::ConfigLoader->new;
isa_ok $loader => "Acore::WAF::ConfigLoader";

my $config = +{
    name => "日本語",
};
my $yaml = "t/tmp/config.yaml";
my $pl   = "t/tmp/config.pl";
file($yaml)->openw->print(encode_utf8( YAML::Dump $config) );
file($pl)->openw->print(encode_utf8 qq|
use utf8;
+{
    name => "日本語",
};
|);

for my $file ($yaml, $pl) {
    my $loaded = $loader->load($file);
    isa_ok $loaded => "HASH";
    is_deeply $loaded => $config, "same object";
    ok utf8::is_utf8($loaded->{"name"}), "is_utf8";
}

unlink "t/tmp/config.yaml";
unlink "t/tmp/config.pl";

done_testing;
