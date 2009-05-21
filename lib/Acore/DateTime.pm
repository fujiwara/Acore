package Acore::DateTime;

use strict;
use warnings;
use UNIVERSAL::require;
our $DT_class = "DateTimeX::Lite";
$DT_class->require;
my %Tz;

sub time_zone {
    my ($class, $name) = shift;
    return $Tz{$name} if defined $Tz{$name};

    my $tz_class = "${DT_class}::TimeZone";
    $Tz{$name} = $tz_class->new($name);
}

sub now {
    $DT_class->now();
}

sub new {
    my $class = shift;
    $DT_class->new(@_);
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
    return $DT_class->new(
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

