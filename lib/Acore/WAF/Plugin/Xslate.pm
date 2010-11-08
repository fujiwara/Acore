package Acore::WAF::Plugin::Xslate;

use strict;
use warnings;
use Text::Xslate 0.2;
use Any::Moose "::Role";

has renderer_xs => (
    is         => "rw",
    lazy_build => 1,
);

sub _build_renderer_xs {
    my $c = shift;
    my $config = $c->config->{xslate} || {};

    $config->{path}   ||= [ $c->path_to('templates')->stringify ];
    $config->{syntax} ||= "TTerse";
    $config->{module} ||= [ "Text::Xslate::Bridge::TT2Like" ];

    $config->{cache} = defined $config->{cache} ?  $config->{cache} : 1;
    $config->{cache_dir} ||= $c->path_to('tmp')->subdir(".xslate")->stringify;

    Text::Xslate->new($config);
}

sub render_xs {
    my ($self, $tmpl) = @_;
    $self->res->body( $self->render_part_xs($tmpl) );
}

sub render_part_xs {
    my $c      = shift;
    my $tmpl   = shift;
    my $output = "";
    $c->renderer_xs->render(
        $tmpl,
        { c => $c, %{ $c->stash } },
    );
}

1;
__END__

=head1 NAME

Acore::WAF::Plugin::Xslate - AnyCMS Xslate plugin

=head1 SYNOPSIS

 YourApp->setup(qw/ Xslate /);
 $config->{xslate} = {
     # Xslate config options
 };

 package YourApp::Controller;
 sub foo {
     my ($self, $c) = @_;
     $c->render_xs('foo.tt');
 }

=head1 DESCRIPTION

Acore template plugin using Template-Toolkit.

=head1 EXPORT METHODS

=over 4

=item render_xs

Render Xslate template and set result to $c->res->body;

=item render_part_xs

Render Xslate template.

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

Template-Toolkit

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
