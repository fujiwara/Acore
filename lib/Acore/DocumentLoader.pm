package Acore::DocumentLoader;

use strict;
use warnings;
use Any::Moose;
use UNIVERSAL::require;

my $Separator = "---";
my $Use_xs;
eval {
    require YAML::XS;
    $Use_xs = 1;
};
if ($@) {
    require YAML;
}

has acore => (
    is  => "rw",
    isa => "Acore",
);

has errors => (
    is      => "rw",
    isa     => "ArrayRef",
    default => sub { [] },
);

has debug => (
    is      => "rw",
    default => 0,
);

has loaded => (
    is      => "rw",
    default => 0,
);

sub load {
    my $self = shift;
    my $arg  = shift;

    $self->loaded(0);
    if (ref $arg) {
        $self->_load_from_stream($arg);
    }
    else {
        $self->_load_from_string($arg);
    }
}

sub add_error {
    my $self  = shift;
    my $error = shift;
    push @{ $self->{errors} }, $error;
}

sub has_error {
    my $self  = shift;
    return scalar @{ $self->{errors} };
}

sub _load_from_stream {
    my $self   = shift;
    my $handle = shift;

    my $buffer = '';
    my $count  = 0;
 LINE:
    while ( my $line = <$handle> ) {
        utf8::decode($line) if !$Use_xs && utf8::is_utf8($line);
        $count++;
        if ( $line =~ /^$Separator$/ && $buffer ) {
            $self->_load_object($buffer, $count);
            $buffer = '';
            next LINE;
        }
        $buffer .= $line;
    }
    $self->_load_object($buffer) if $buffer;
}

sub _load_from_string {
    my $self  = shift;
    my $str   = shift;
    my @yaml  = split /\n$Separator\n/, $str;
    my $count = 0;
    for my $yaml (@yaml) {
        $count++;
        $self->_load_object($yaml . "\n", $count);
    }
}
use Data::Dumper;
sub _load_object {
    my $self   = shift;
    my ($yaml, $count) = @_;
    my $object = eval { $Use_xs ? YAML::XS::Load($yaml) : YAML::Load($yaml) };
    if ($@) {
        $self->add_error("Can't load from YAML at line $count. $@");
        return;
    }
    if (! ref $object eq 'HASH') {
        $self->add_error("no HASH ref. $object");
        return;
    }

    my $class = $object->{_class} ||= "Acore::Document";
    $class->require
        or return $self->add_error("Cant't require $class at line $count. $@");

    my $document = $class->from_object($object);
    eval {
        $self->acore->put_document($document);
    };
    if ($@) {
        $self->add_error("Can't load into Acore. $@");
    }
    else {
        $self->{loaded}++;
    }
}

1;

__END__

=head1 NAME

Acore::DocumentLoader - document loader class

=head1 SYNOPSIS

  $loader = Acore::DocumentLoader->new({ acore => $acore });
  $loader->load($fh);
  $loader->load($str);
  if ($loader->has_error) {
      @errors = @{ $loader->errors };
  }

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item new

Constractor.

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

L<Acore>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
