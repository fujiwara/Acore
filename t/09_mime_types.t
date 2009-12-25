# -*- mode:perl -*-
use strict;
use warnings;
use Test::Base;

plan tests => (1 + (1 * blocks));

use_ok("Acore::MIME::Types");

filters {
    ext  => [qw/chomp mime_type/],
    mime => [qw/chomp/],
};

Acore::MIME::Types->add_type(
    xxx => "application/x-xxx",
    yyy => "application/x-yyy",
);

run {
    my $block  = shift;
    is $block->ext => $block->mime, "test of ". $block->ext;
};

sub mime_type {
    Acore::MIME::Types->mime_type($_[0]);
}

__END__

===
--- ext
jpg
--- mime
image/jpeg

===
--- ext
png
--- mime
image/png

===
--- ext
html
--- mime
text/html

===
--- ext
css
--- mime
text/css

===
--- ext
js
--- mime
application/javascript

===
--- ext
txt
--- mime
text/plain

===
--- ext
swf
--- mime
application/x-shockwave-flash

===
--- ext
xxx
--- mime
application/x-xxx

===
--- ext
yyy
--- mime
application/x-yyy


