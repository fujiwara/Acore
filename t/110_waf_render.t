# -*- mode:perl -*-
use strict;
use Test::Base;
use Test::More;
use utf8;
use Acore::Document;
use Acore::WAF::Render;
use Encode qw/ encode_utf8 /;

{
    no warnings;
    sub html {
        package Acore::WAF::Render;
        $_[0] | html
    }
    sub utf8 {
        package Acore::WAF::Render;
        $_[0] | utf8
    }
    sub uri  {
        package Acore::WAF::Render;
        $_[0] | uri
    }
    sub uri_un {
        package Acore::WAF::Render;
        $_[0] | uri_unescape;
    }
    sub html_line_break {
        package Acore::WAF::Render;
        $_[0] | html_line_break
    }
    sub replace {
        package Acore::WAF::Render;
        my ($val, $reg, $rep) = split / +/, $_[0];
        $val | replace($reg, $rep);
    }
    sub js {
        package Acore::WAF::Render;
        $_[0] | js
    }
    sub fillform {
        package Acore::WAF::Render;
        $_[0] | fillform({ foo => 1, bar => 2 });
    }
    sub sort_by {
        package Acore::WAF::Render;
        my ($key) = split / +/, $_[0];

        my $arr_ref = [
            { num => 1000, name => 'beta'  },
            { num => 200,  name => 'alpha' }
        ];
        my $expct = '';
        for my $d ( @{ $arr_ref | sort_by($key) } ) {
            $expct .= $d->{name};
        }

        $expct;
    }

    sub nsort_by {
        package Acore::WAF::Render;
        my ($key) = split / +/, $_[0];

        my $arr_ref = [
            { num => 1000, name => 'beta'  },
            { num => 200,  name => 'alpha' }
        ];
        my $expct = '';
        for my $d ( @{ $arr_ref | nsort_by($key) } ) {
            $expct .= $d->{name};
        }

        $expct;
    }

    sub json {
        package Acore::WAF::Render;
        eval($_[0]) | json;
    };
}

run_is input => 'expected';

done_testing;

__END__

=== html
--- input chomp html
<a href="javascript:foo('a&b')"></a>
--- expected chomp
&lt;a href=&quot;javascript:foo(&#39;a&amp;b&#39;)&quot;&gt;&lt;/a&gt;

=== utf8
--- input chomp utf8
日本語
--- expected chomp
日本語

=== utf8 no flagged
--- input chomp encode_utf8 utf8
日本語
--- expected chomp
日本語

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

=== uri_unescape
--- input chomp uri_un
a%3Db%26c%3Dd
--- expected chomp
a=b&c=d

=== uri_unescape utf8
--- input chomp uri_un
%E3%81%82%E3%81%84%E3%81%86
--- expected chomp
あいう

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
<input type="text" name="foo" value="1"/>
<input type="text" name="bar" value="2"/>

=== sort_by string
--- input chomp sort_by
name
--- expected chomp
alphabeta

=== sort_by number
--- input chomp sort_by
num
--- expected chomp
betaalpha

=== nsort_by string
--- input chomp nsort_by
name
--- expected chomp
betaalpha

=== nsort_by number
--- input chomp nsort_by
num
--- expected chomp
alphabeta

=== json
--- input chomp json
{ A => 1, B => 2 }
--- expected chomp
{"A":1,"B":2}

