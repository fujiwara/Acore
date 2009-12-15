package Acore::WAF::Render;

use strict;
use warnings;
use URI::Escape ();
use Encode ();
use Sub::Pipe;
use Data::Dumper;

our $Location;
sub set_location { $Location = $_[0] }
sub location     { $Location }

sub raw {
    if (@_) {
        return Text::MicroTemplate::encoded_string($_[0]);
    }
    return joint {
        Text::MicroTemplate::encoded_string($_[0]);
    };
}

sub r {
    warn "'?=r' and '<?=r ?>' was deprecated! Use 'raw' instead.\n";
    Text::MicroTemplate::encoded_string($_[0]);
}

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

sub utf8() { ## no critic
    joint {
        my $input = $_[0];
        $input = Encode::decode_utf8($input)
            unless utf8::is_utf8($input);
        $input;
    };
}

sub uri_unescape() {  ## no critic
    joint {
        my $input = $_[0];
        utf8::encode($input) if utf8::is_utf8($input);
        Encode::decode_utf8(
            URI::Escape::uri_unescape($input)
        );
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

sub sort_by($) { ## no critic
    my $key = shift;
    joint {
        return if ref($_[0]) ne 'ARRAY';
        [ sort { $a->{$key} cmp $b->{$key} } @{$_[0]} ];
    }
}

sub nsort_by($) { ## no critic
    my $key = shift;
    joint {
        return if ref($_[0]) ne 'ARRAY';
        [ sort { $a->{$key} <=> $b->{$key} } @{$_[0]} ];
    }
}

my $Json;
sub json {
    my ($pretty) = shift;
    joint {
        $Json ||= do { require JSON; JSON->new };
        my $json = $pretty ? $Json->pretty: $Json;
        ref $_[0] ? $json->encode($_[0]) : $_[0];
    };
}

1;
__END__

=head1 NAME

Acore::WAF::Render - Rendering package

=head1 SYNOPSIS

In Text::MicroTemplate like TT.

 <?= $foo | html | raw ?>
 <?= $foo | html | html_line_break | raw ?>
 <?= $foo | uri ?>
 <?= $foo | replace('a','b') ?>
 <?= $array_ref | join(',') ?>
 <?= $foo | js ?>
 <?= $html | fillform($c->req) ?>
 <?= $array_ref | sort_by('foo') ?>
 <?= $array_ref | nsort_by('bar') ?>
 <?= $no_flagged_string | utf8 ?>

=head1 DESCRIPTION

Acore is AnyCMS core module.

=head1 METHODS

=over 4

=item raw

Turn off HTML escape by Text::MicroTemplate.

=item ut8

Turn on UTF8 flag if not flagged input.

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

=item sort_by($key)

Hashref or Acore::Document sort by key.

=item nsort_by($key)

Hashref or Acore::Document numeric sort by key.

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
