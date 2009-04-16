package Acore::DateTime;

use strict;
use warnings;
use DateTimeX::Lite;

sub now {
    DateTimeX::Lite->now();
}

sub new {
    my $class = shift;
    DateTimeX::Lite->new(@_);
}

sub parse_datetime {
    my $class = shift;
    my $str   = shift;
    unless ($str) {
        my @c = caller();
        die "no arg: @c";
    }

    my @d = ( $str =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z$/ );
    return unless @d;
    return DateTimeX::Lite->new(
        year   => $d[0],
        month  => $d[1],
        day    => $d[2],
        hour   => $d[3],
        minute => $d[4],
        second => $d[5],
    );
}

sub format_datetime {
    my $class = shift;
    my $date  = shift;
    return sprintf "%sT%sZ", $date->ymd("-"), $date->hms(":");
}

1;

