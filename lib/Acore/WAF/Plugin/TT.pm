package Acore::WAF::Plugin::TT;

use strict;
use warnings;
use Template 2.20;

require Exporter;
our @EXPORT = qw/ render render_part _build_renderer /;

no warnings 'redefine';

sub _build_renderer {
    my $c = shift;
    $c->config->{tt}->{ENCODING} ||= 'utf-8';
    Template->new($c->config->{tt});
}

sub render {
    my $c = shift;
    $c->res->body( $c->encoder->encode( $c->render_part(@_) ) );
}

sub render_part {
    my $c      = shift;
    my $tmpl   = shift;
    my $output = "";
    $c->renderer->process(
        $tmpl,
        { c => $c, %{ $c->stash } },
        \$output,
    );
    $output;
}

1;
