package Acore::WAF::Controller::AdminConsole::BareBone::Model;
use DBIx::Skinny;
use strict;
use warnings;

sub tables {
    my $self = shift;

    if ($self->dbd =~ /Pg/) {
        my @tables = $self->dbh->tables( "", "public" );
        for (@tables) {
            s/^public\.//;
            s/"//g;
        }
        return sort { $a cmp $b } @tables;
    }
    elsif ($self->dbd =~ /::SQLite/) {
        my @tables = grep !/^"sqlite_/, $self->dbh->tables();
        for (@tables) {
            s/"//g;
        }
        return sort { $a cmp $b } @tables;
    }
}

sub primary_key_info {
    my $self  = shift;
    my $table = shift;

    my $sth;
    if ($self->dbd =~ /Pg/) {
        $sth = $self->dbh->primary_key_info( "", "public", $table );
    }
    elsif ($self->dbd =~ /::SQLite/) {
        $sth = $self->dbh->primary_key_info( "", "", $table );
    }
    return $sth ? $sth->fetchall_hashref("COLUMN_NAME") : {};
}

sub columns_info {
    my $self  = shift;
    my $table = shift;

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare("SELECT * FROM $table WHERE 1=0");
    $sth->execute;
    my @cols = @{ $sth->{NAME_lc} };
    $sth->finish;
    my @columns_info;
    for my $col (@cols) {
        my $info = $dbh->column_info("", "", $table, $col)
                       ->fetchall_hashref("TABLE_NAME");
        push @columns_info, $info->{$table};
    }
    return @columns_info;
}

1;

