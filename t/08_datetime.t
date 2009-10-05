# -*- mode:perl -*-
use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;
our @class;
BEGIN {
    @class = qw/ DateTime /;
    my $tests = 29;
    eval { require DateTimeX::Lite; };
    push @class, "DateTimeX::Lite" unless $@;
    plan tests => $@ ? (2 + $tests) : (2 + $tests * 2);
    use_ok 'Acore::DateTime';
    use_ok 'DateTime';
};

for my $dt_class (@class) {
local $Acore::DateTime::DT_class = $dt_class;
$dt_class->require;
{
    my $d = Acore::DateTime->now;
    isa_ok $d => $Acore::DateTime::DT_class;
}

{
    my $d = Acore::DateTime->new(
        year   => 2009,
        month  => 5,
        day    => 13,
        hour   => 18,
        minute => 47,
        second => 33,
    );
    isa_ok $d => $Acore::DateTime::DT_class;
    is $d->year   => 2009;
    is $d->month  => 5;
    is $d->day    => 13;
    is $d->hour   => 18;
    is $d->minute => 47;
    is $d->second => 33;

    is $d->ymd      => "2009-05-13";
    is $d->ymd("/") => "2009/05/13";
    is $d->hms      => "18:47:33";
    is $d->hms(".") => "18.47.33";
}

{
    throws_ok { Acore::DateTime->parse_datetime("xxx") } qr/Invalid/;
    throws_ok { Acore::DateTime->parse_datetime }        qr/Invalid/;

    my $d = Acore::DateTime->parse_datetime("2009-05-13T18:47:33Z");

    isa_ok $d => $Acore::DateTime::DT_class;
    is $d->year   => 2009;
    is $d->month  => 5;
    is $d->day    => 13;
    is $d->hour   => 18;
    is $d->minute => 47;
    is $d->second => 33;
}

{
    my $d = Acore::DateTime->new(
        year   => 2009,
        month  => 5,
        day    => 13,
        hour   => 9,
        minute => 47,
        second => 33,
    );
    is $d->ymd => "2009-05-13";
    is $d->hms => "09:47:33";
    is $d->time_zone->name => "Asia/Tokyo", "default tz is Asia/Tokyo";

    my $formated = Acore::DateTime->format_datetime($d);
    is $formated => "2009-05-13T09:47:33+09:00";

    $d->set_time_zone("UTC");
    my $tz = $d->time_zone;
    is $tz->name => 'UTC', "tz name";

    is $d->ymd => "2009-05-13";
    is $d->hms => "00:47:33";

    $formated = Acore::DateTime->format_datetime($d);
    is $formated => "2009-05-13T00:47:33Z";
}

}
