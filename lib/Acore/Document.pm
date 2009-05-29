package Acore::Document;

use strict;
use warnings;
use Clone qw/ clone /;
use Scalar::Util qw/ blessed /;
use Data::Structure::Util qw/ unbless /;
use UNIVERSAL::require;
use Acore::DateTime;
use Any::Moose;
use Any::Moose 'Util::TypeConstraints';

subtype 'DateTime'
    => as 'Object',
    => where { $_->isa($Acore::DateTime::DT_class) };

coerce 'DateTime'
    => from 'Str',
    => via { Acore::DateTime->parse_datetime($_) };

has id => (
    is => "rw",
);

has path => (
    is => "rw",
);

has content_type => (
    is      => "rw",
    default => "text/plain",
);

has tags => (
    is      => "rw",
    default => sub { [] },
);

has created_on => (
    is         => "rw",
    isa        => "DateTime",
    lazy_build => 1,
    coerce     => 1,
);

has updated_on => (
    is         => "rw",
    isa        => "DateTime",
    lazy_build => 1,
    coerce     => 1,
);

sub _build_created_on {
    Acore::DateTime->now( time_zone => "local" )
}

sub _build_updated_on {
    Acore::DateTime->now( time_zone => "local" )
}

sub BUILD {
    my ($self, $obj) = @_;
    for my $n ( keys %$obj ) {
        $self->{$n} = $obj->{$n} unless exists $self->{$n};
    }
    $self;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

sub to_object {
    my $self = shift;
    my $obj  = clone $self;

    require Acore::DateTime;
    $obj->{created_on} = Acore::DateTime->format_datetime( $obj->created_on );
    $obj->{updated_on} = Acore::DateTime->format_datetime( $obj->updated_on );
    $obj->{_class}     = ref $self;
    $obj->{_id} = delete $obj->{id} if $obj->{id};
    unbless $obj;

    return $obj;
}

sub from_object {
    my $class = shift;
    my $obj   = shift;
    $obj->{_class}->require;
    $obj->{id} = delete $obj->{_id} if $obj->{_id};
    $obj->{_class}->new($obj);
}

sub as_string {
    my $self = shift;
    require Data::Dumper;
    local $Data::Dumper::Indent = 1;
    return Data::Dumper::Dumper($self);
}

1;
__END__

=head1 NAME

Acore::Document - document base class

=head1 SYNOPSIS

  package YourDocument;
  use Any::Moose;
  extends 'Acore::Document';
  has foo => (
     is => "rw",
  );

  $doc = YourDocument->new({
      path => "/foo/bar",
      foo  => "bar",
  });
  $acore->put_document($doc);

=head1 DESCRIPTION

Acore::Document is AnyCMS schema less document class.

=head1 ATTRIBUTES

=over 4

=item id

=item path

=item tags

=item content_type

=item created_on

=item updated_on

=back

=head1 METHODS

=over 4

=item new

Constractor.

=item to_object

Convert to plain object (hash ref). Called before Acore->put_document().

 $hash_ref = $doc->to_object;

=item from_object

Class method.

Convert from plain object (hash ref). Called after Acore->get_document().

 $doc = YourDocument->from_object($hash_ref);

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
