package Acore::Document;

use strict;
use warnings;
use base qw/ Class::Accessor::Fast /;
use DateTime;
use DateTime::Format::W3CDTF;
use Clone qw/ clone /;
use Scalar::Util qw/ blessed /;
use Data::Structure::Util qw/ unbless /;

__PACKAGE__->mk_accessors(qw/ path content_type /);

my $DT_format = DateTime::Format::W3CDTF->new;

sub id {
    my $self = shift;
    $self->{_id};
}

for my $name (qw/ created_on updated_on /) {
    no strict "refs";
    *{$name} = sub {
        use strict;
        my $self = shift;
        if (@_) {
            my $value = shift;
            $self->{$name}
                = ( blessed $value && $value->isa('DateTime') )
                    ? $value
                    : $DT_format->parse_datetime($value);
        }
        unless ( blessed $self->{$name} ) {
            $self->{$name} = $DT_format->parse_datetime($self->{$name});
        }
        $self->{$name};
    }
}

sub to_object {
    my $self = shift;
    my $obj  = clone $self;

    $obj->{created_on} = $DT_format->format_datetime($obj->{created_on});
    $obj->{updated_on} = $DT_format->format_datetime($obj->{updated_on});
    $obj->{_class}     = ref $self;
    unbless $obj;

    return $obj;
}

sub from_object {
    my $class = shift;
    my $obj   = shift;
    return bless $obj, $obj->{_class} || $class;
}

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{$_} ||= Acore->now()
        for qw/ created_on updated_on /;
    $self;
}

1;
