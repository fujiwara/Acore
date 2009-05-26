package Acore::Document;

use strict;
use warnings;
use base qw/ Class::Accessor::Fast /;
use Clone qw/ clone /;
use Scalar::Util qw/ blessed /;
use Data::Structure::Util qw/ unbless /;
use UNIVERSAL::require;

__PACKAGE__->mk_accessors(qw/ path content_type tags /);

sub id {
    my $self = shift;
    $self->{_id};
}

for my $name (qw/ created_on updated_on /) {
    no strict "refs";
    *{$name} = sub {
        use strict;
        require Acore::DateTime;

        my $self = shift;
        if (@_) {
            my $value = shift;
            $self->{$name}
                = blessed $value
                    ? $value
                    : Acore::DateTime->parse_datetime($value);
        }
        unless ( blessed $self->{$name} ) {
            $self->{$name} = Acore::DateTime->parse_datetime($self->{$name});
        }
        $self->{$name};
    }
}

sub to_object {
    my $self = shift;
    my $obj  = clone $self;

    require Acore::DateTime;
    $obj->{created_on} = Acore::DateTime->format_datetime( $obj->created_on );
    $obj->{updated_on} = Acore::DateTime->format_datetime( $obj->updated_on );
    $obj->{_class}     = ref $self;
    unbless $obj;

    return $obj;
}

sub from_object {
    my $class = shift;
    my $obj   = shift;
    $obj->{_class}->require;
    return bless $obj, $obj->{_class} || $class;
}

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    require Acore::DateTime;
    $self->{$_} ||= Acore::DateTime->now( time_zone => "local" )
        for qw/ created_on updated_on /;
    $self;
}

sub as_string {
    my $self = shift;
    require Data::Dumper;
    local $Data::Dumper::Indent = 1;
    return Data::Dumper::Dumper($self);
}

sub tags {
    my $self = shift;
    $self->{tags} ||= [];
    return wantarray ? @{ $self->{tags} } : $self->{tags};
}

1;
