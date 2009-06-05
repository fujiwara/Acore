package Acore::DateTime;

use strict;
use warnings;
use UNIVERSAL::require;
our $DT_class = "DateTime";
$DT_class->require;

our $TZ = "Asia/Tokyo";

sub now {
    my $class = shift;
    my %args  = @_;
    $args{time_zone} ||= $TZ;
    $DT_class->now(%args);
}

sub new {
    my $class = shift;
    my %args  = @_;
    $args{time_zone} ||= $TZ;
    $DT_class->new(%args);
}

## copied from DateTime::Format::W3CDTF.

my %valid_formats =
    ( 19 =>
      { params => [ qw( year month day hour minute second) ],
        regex  => qr/^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)$/,
        zero   => {},
      },
      16 =>
      { params => [ qw( year month day hour minute) ],
        regex  => qr/^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d)$/,
        zero   => { second => 0 },
      },
      10 =>
      { params => [ qw( year month day ) ],
        regex  => qr/^(\d{4})-(\d\d)-(\d\d)$/,
        zero   => { hour => 0, minute => 0, second => 0 },
      },
      7 =>
      { params => [ qw( year month ) ],
        regex  => qr/^(\d{4})-(\d\d)$/,
        zero   => { day => 1, hour => 0, minute => 0, second => 0 },
      },
      4 =>
      { params => [ qw( year ) ],
        regex  => qr/^(\d\d\d\d)$/,
        zero   => { month => 1, day => 1, hour => 0, minute => 0, second => 0 }
      }
    );

sub parse_datetime {
    my ( $self, $date ) = @_;

    # save for error messages
    my $original = $date;

    my %p;
    if ( $date =~ s/([+-]\d\d:\d\d)$// ) {
        $p{time_zone} = $1;
    }
    # Z at end means UTC
    elsif ( $date =~ s/Z$// ) {
        $p{time_zone} = 'UTC';
    }
    else {
        $p{time_zone} = 'floating';
    }

    my $format = $valid_formats{ length $date }
        or die "Invalid W3CDTF datetime string ($original)";

    @p{ @{ $format->{params} } } = $date =~ /$format->{regex}/;

    return $DT_class->new( %p, %{ $format->{zero} } );
}

sub format_datetime {
    my ( $self, $dt ) = @_;

    my $base = sprintf(
        '%04d-%02d-%02dT%02d:%02d:%02d',
        $dt->year, $dt->month, $dt->day,
        $dt->hour, $dt->minute, $dt->second,
    );

    my $tz = $dt->time_zone;
    return $base if $tz->is_floating;
    return $base . 'Z' if $tz->is_utc;

    if (my $offset = $dt->offset()) {
        return $base . offset_as_string($offset);
    }
}

sub offset_as_string {
    my $offset = shift;

    return unless defined $offset;

    my $sign = $offset < 0 ? '-' : '+';

    my $hours = $offset / ( 60 * 60 );
    $hours = abs($hours) % 24;

    my $mins = ( $offset % ( 60 * 60 ) ) / 60;

    my $secs = $offset % 60;

    return ( $secs ?
             sprintf( '%s%02d:%02d:%02d', $sign, $hours, $mins, $secs ) :
             sprintf( '%s%02d:%02d', $sign, $hours, $mins )
           );
}

1;

