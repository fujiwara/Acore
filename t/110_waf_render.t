# -*- mode:perl -*-
use strict;
use Test::Base;
use utf8;

plan tests => ( 1 + (1 * blocks) );

use_ok("Acore::WAF::Render");

{
    no warnings;
    sub html {
        $_[0] | Acore::WAF::Render::html()
    }
    sub uri  {
        $_[0] | Acore::WAF::Render::uri()
    }
    sub html_line_break {
        $_[0] | Acore::WAF::Render::html_line_break()
    }
    sub replace {
        my ($val, $reg, $rep) = split / +/, $_[0];
        $val | Acore::WAF::Render::replace($reg, $rep);
    }
    sub _join {
        my ($sep, @list) = split / +/, $_[0];
        [ @list ] | Acore::WAF::Render::join($sep);
    }
    sub _fjoin {
        my ($sep, @list) = split / +/, $_[0];
        Acore::WAF::Render::join($sep, @list);
    }
    sub js {
        $_[0] | Acore::WAF::Render::js();
    }
    sub fillform {
        $_[0] | Acore::WAF::Render::fillform({ foo => 1, bar => 2 });
    }

}

run_is input => 'expected';

__END__

=== html
--- input chomp html
<a href="javascript:foo('a&b')"></a>
--- expected chomp
&lt;a href=&quot;javascript:foo(&#39;a&amp;b&#39;)&quot;&gt;&lt;/a&gt;

=== uri
--- input chomp uri
a=b&c=d
--- expected chomp
a%3Db%26c%3Dd

=== uri utf8
--- input chomp uri
あいう
--- expected chomp
%E3%81%82%E3%81%84%E3%81%86

=== replace
--- input chomp replace
foobar   foo   bar
--- expected chomp
barbar

=== replace utf8
--- input chomp replace
あいうえお   [あい]  *
--- expected chomp
**うえお

=== html_line_break
--- input chomp html_line_break
A
B
C
--- expected chomp
A<br/>B<br/>C

=== pipe join
--- input chomp _join
, A B C
--- expected chomp
A,B,C

=== pipe join
--- input chomp _join
+ あ い う
--- expected chomp
あ+い+う

=== functional join
--- input chomp _fjoin
, A B C
--- expected chomp
A,B,C

=== js
--- input chomp js
A	B
"C"'D'
--- expected chomp
A\tB\n\"C\"\'D\'

=== fillform
--- input chomp fillform
<input type="text" name="foo" value=""/>
<input type="text" name="bar" value=""/>
--- expected chomp
<input value="1" name="foo" type="text" />
<input value="2" name="bar" type="text" />

