package Acore::Storage;

use strict;
use warnings;
our $VERSION = '0.01';
use base qw/ Class::Accessor::Fast /;
use DBIx::CouchLike;

__PACKAGE__->mk_accessors(qw/ dbh user document /);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    for my $table (qw/ user document /) {
        $self->$table(
            DBIx::CouchLike->new({
                dbh   => $self->dbh,
                table => "acore_$table",
            })
        );
    }
    return $self;
}

sub setup {
    my $self = shift;
    $self->user->create_table();
    $self->document->create_table();
}

1;
__END__

=head1 NAME

Acore::Storage -

=head1 SYNOPSIS

  use Acore::Storage;

=head1 DESCRIPTION

Acore is

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
