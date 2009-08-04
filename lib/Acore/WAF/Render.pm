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

sub uri_unescape() {  ## no critic
    joint {
        my $input = $_[0];
        utf8::encode($input) if utf8::is_utf8($input);
        my $output = URI::Escape::uri_unescape($input);
        utf8::decode($output) unless utf8::is_utf8($output);
        $output;
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

*CORE::GLOBAL::join = sub {
    my $sep = shift;
    ( @_ == 0 && (caller)[0] eq __PACKAGE__ )
        ? joint { CORE::join( $sep, @{ $_[0] } ) }
        : CORE::join( $sep, @_ );
};

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

 <?=r $foo | html ?>
 <?=r $foo | html | html_line_break ?>
 <?=  $foo | uri ?>
 <?=  $foo | replace('a','b') ?>
 <?=  $array_ref | join(',') ?>
 <?=  $foo | js ?>
 <?=  $html | fillform($c->req) ?>
 <?=  $array_ref | sort_by('foo') ?>
 <?=  $array_ref | nsort_by('bar') ?>

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
