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

    my $parent = "Acore::WAF::Controller::AdminConsole";
    $c->forward( $parent => "_auto", $args );
    $c->forward( $parent => "is_logged_in" );

    my $dsn   = $c->config->{barebone}->{dsn} || $c->config->{dsn};
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

sub _table_info {
    my ($self, $c, $args) = @_;

    my $name  = $args->{name};
    my $model = $c->stash->{model};
    if ($name !~ /\A[a-zA-Z0-9_]+\z/) {
        $c->error( 404 => "table not found" );
    }
    $c->stash->{columns_info} = [ $model->columns_info($name) ];
    $c->stash->{table} = $name;
    $c->stash->{primary_key_info} = $model->primary_key_info($name);
}

sub table_info {
    my ($self, $c, $args) = @_;
    $c->forward( $self => "_table_info", $args );
    $c->render("admin_console/barebone/table_info.mt");
}

sub table_select {
    my ($self, $c, $args) = @_;

    $c->forward( $self => "_table_info", $args );

    require SQL::Abstract;
    my $sql = SQL::Abstract->new;
    my $where = $c->req->param("where");
    my $order = $c->req->param("order_by") || "";
    $order .= " DESC" if $c->req->param("desc");
    my ($stmt, @bind)
        = $sql->select(
            $c->stash->{table},
            [ $c->req->param("cols") ],
            \$where,
            ($order ? \$order : undef),
        );
    $stmt .= sprintf " LIMIT %d", $c->req->param("limit")
        if $c->req->param("limit");

    $c->stash->{sql} = $stmt;
    $c->log->debug("sql: $stmt");

    my $model  = $c->stash->{model};
    $c->stash->{result} = $model->search_by_sql($stmt, \@bind);

    $c->render("admin_console/barebone/table_info.mt");
    $c->fillform;
}

1;
