package Acore::WAF::Plugin::TT;

use strict;
use warnings;
use Template 2.20;

require Exporter;
our @EXPORT = qw/ render render_part _build_renderer /;

no warnings 'redefine';

sub _build_renderer {
    my $c = shift;
    my $config = $c->config->{tt};
    $config->{ENCODING}     ||= 'utf-8';
    $config->{INCLUDE_PATH} ||= $c->path_to('templates')->stringify;
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
    ) or die $c->renderer->error();
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
     $c->render('foo.tt');
 }

=head1 DESCRIPTION

Acore template plugin using Template-Toolkit.

Default TT options are

  INCLUDE_PATH => "root/templates",
  ENCODING     => "utf-8",


=head1 EXPORT METHODS

=over 4

=item render

Override default $c->render.

=item render_part

Override default $c->render_part.

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

Template-Toolkit

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
