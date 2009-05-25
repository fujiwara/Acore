package Acore::WAF::Render;

use strict;
use warnings;
use URI::Escape;
use Sub::Pipe;

sub html() { ## no critic
    joint {
        local $_ = $_[0];
        s{&}{&amp;}g;
        s{<}{&lt;}g;
        s{>}{&gt;}g;
        s{"}{&quot;}g;
        s{'}{&#39;}g;
        $_;
    };
}

sub uri() {  ## no critic
    joint {
        URI::Escape::uri_escape_utf8($_[0]);
    };
}

sub replace($$) {  ## no critic
    my ( $regex, $replace ) = @_;
    joint {
        local $_ = $_[0];
        s{$regex}{$replace}g;
        $_;
    };
}

sub html_line_break() { ## no critic
    joint {
        local $_ = $_[0];
        s{\r*\n}{<br/>}g;
        $_;
    };
}

sub list_join {
    my ($sep) = shift;
    joint {
        my @list = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
        join($sep, @list);
    };
}

1;
__END__


