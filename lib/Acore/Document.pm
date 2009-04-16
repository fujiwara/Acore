package Acore::Document;

use strict;
use warnings;
use base qw/ Class::Accessor::Fast /;
use Scalar::Util qw/ blessed /;
use DateTime;
use DateTime::Format::W3CDTF;

__PACKAGE__->mk_accessors(qw/ path content_type /);

my $DT_format = DateTime::Format::W3CDTF->new;

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
        $self->{$name};
    }
}

sub _before_serialize {
    my $self = shift;
    $self->{created_on} = $DT_format->format_datetime($self->{created_on});
    $self->{updated_on} = $DT_format->format_datetime($self->{updated_on});
}

sub _after_deserialize {
    my $self = shift;
    $self->{created_on} = $DT_format->parse_datetime($self->{created_on});
    $self->{updated_on} = $DT_format->parse_datetime($self->{updated_on});
}

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{$_} ||= Acore->now()
        for qw/ created_on updated_on /;
    $self;
}

1;
