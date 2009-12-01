package Acore::WAF::Controller::AdminConsole::BareBone;

use strict;
use warnings;
use Scalar::Util qw/ blessed /;
use utf8;
use Acore::WAF::Controller::AdminConsole;
use Data::Dumper;
use Acore::WAF::Controller::AdminConsole::BareBone::Model;

use Any::Moose;
with "Acore::WAF::Controller::Role::Locatable";

no Any::Moose;
__PACKAGE__->meta->make_immutable;

my $Model = __PACKAGE__ . "::Model";
sub _auto {
    my ($self, $c, $args) = @_;
    Acore::WAF::Controller::AdminConsole::_auto(@_);

    my $dsn   = $c->config->{dsn};
    my $model = $Model->new;
    $model->connect_info({
        dsn             => $dsn->[0],
        username        => $dsn->[1],
        password        => $dsn->[2],
        connect_options => $dsn->[3] || {},
    });
    $c->stash->{model} = $model;
    1;
}

sub table_list {
    my ($self, $c) = @_;

    my @tables = $c->stash->{model}->tables;
    $c->stash->{tables} = \@tables;
    $c->render("admin_console/barebone/table_list.mt");
}

sub table_info {
    my ($self, $c, $args) = @_;

    my $name  = $args->{name};
    my $model = $c->stash->{model};
    if ($name !~ /\A[a-zA-Z0-9_]+\z/) {
        $c->error( 404 => "table not found" );
    }
    $c->stash->{columns_info} = [ $model->columns_info($name) ];
    $c->stash->{table} = $name;
    $c->stash->{primary_key_info} = $model->primary_key_info($name);

    $c->render("admin_console/barebone/table_info.mt");
}

1;
