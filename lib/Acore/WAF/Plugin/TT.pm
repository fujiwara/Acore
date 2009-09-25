package Acore::WAF::Plugin::TT;

use strict;
use warnings;
use Template 2.20;
use Any::Moose "::Role";

has renderer_tt => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        my $c = shift;
        my $config = $c->config->{tt} || {};
        $config->{ENCODING}     ||= 'utf-8';
        $config->{INCLUDE_PATH} ||= $c->path_to('templates')->stringify;
        Template->new($config);
    },
);

sub render_tt {
    my ($self, $tmpl) = @_;
    $self->res->body( $self->render_part_tt($tmpl) );
}

sub render_part_tt {
    my $c      = shift;
    my $tmpl   = shift;
    my $output = "";
    $c->renderer_tt->process(
        $tmpl,
        { c => $c, %{ $c->stash } },
        \$output,
    ) or die $c->renderer_tt->error();
    $output;
}

1;
__END__

=head1 NAME

Acore::WAF::Plugin::TT - AnyCMS Template-Toolkit plugin

=head1 SYNOPSIS

 YourApp->setup(qw/ TT /);
 $config->{tt} = {
     # TT config options
 };

 package YourApp::Controller;
 sub foo {
     my ($self, $c) = @_;
     $c->render_tt('foo.tt');
 }

=head1 DESCRIPTION

Acore template plugin using Template-Toolkit.

Default TT options are

  INCLUDE_PATH => "root/templates",
  ENCODING     => "utf-8",

=head1 EXPORT METHODS

=over 4

=item render_tt

Render TT template and set result to $c->res->body;

=item render_part_tt

Render TT template.

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

Template-Toolkit

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
