# -*- mode:perl -*-
use strict;
use Test::Base;
use utf8;

plan tests => ( 1 + (1 * blocks) );

use_ok("Acore::WAF::Render");

{
    no warnings;
    *html    = *Acore::WAF::Render::html;
    *uri     = *Acore::WAF::Render::uri;
    sub replace {
        my @x = split / +/, $_[0];
        Acore::WAF::Render::replace(@x);
    }
}

run_is input => 'expected';



__END__

===
--- input chomp html
<a href="javascript:foo('a&b')"></a>
--- expected chomp
&lt;a href=&quot;javascript:foo(&#39;a&amp;b&#39;)&quot;&gt;&lt;/a&gt;

===
--- input chomp uri
a=b&c=d
--- expected chomp
a%3Db%26c%3Dd

===
--- input chomp uri
あいう
--- expected chomp
%E3%81%82%E3%81%84%E3%81%86

===
--- input chomp replace
foobar   foo   bar
--- expected chomp
barbar

===
--- input chomp replace
あいうえお   [あい]  *
--- expected chomp
**うえお

