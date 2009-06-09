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

sub join {
    my ($sep) = shift;
    if (@_) {
        CORE::join($sep, @_);
    }
    else {
        joint {
            my @list = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
            CORE::join($sep, @list);
        };
    }
}

sub js {
    joint {
        local $_ = shift;
        return '' unless defined $_;

        s{(['"])}{\\$1}g;
        s{\n}{\\n}g;
        s{\f}{\\f}g;
        s{\r}{\\r}g;
        s{\t}{\\t}g;
        $_;
    };
}

sub fillform {
    my ($obj) = @_;
    joint {
        my ($html) = @_;
        require HTML::FillInForm;
        HTML::FillInForm->fill(\$html, $obj);
    };
}

1;
__END__

=head1 NAME

Acore::WAF::Render - Rendering package

=head1 SYNOPSIS

In Text::MicroTemplate like TT.

 <?=r $foo | html ?>
 <?=r $foo | html | html_line_break ?>
 <?=  $foo | uri ?>
 <?=  $foo | replace('a','b') ?>
 <?=  $array_ref | join(',') ?>
 <?=  $foo | js ?>
 <?=  $html | fillform($c->req) ?>

=head1 DESCRIPTION

Acore is AnyCMS core module.

=head1 METHODS

=over 4

=item html

HTML esacpe.

=item html_line_break

Repalce \r*\n to <br/>.

=item uri

URI escape.

=item replace($regexp, $replacement)

Replace from matchs by $regexp to $replacement.

=item join($separator)

Join array ref by $separator.

=item fillform($obj)

Fill in form by $obj.

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
