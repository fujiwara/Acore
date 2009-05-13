package Acore::WAF::Log;
use strict;
use warnings;
use Any::Moose;
use Carp qw/ carp /;

my $Levels = {
    emerge   => 0,
    alert    => 1,
    critical => 2,
    error    => 3,
    warning  => 4,
    notice   => 5,
    info     => 6,
    debug    => 7,
};

has level => (
    is      => "rw",
    default => "info",
);

has buffer => (
    is      => "rw",
    isa     => "Str",
    defualt => "",
);

has timestamp => (
    is      => "rw",
    default => 1,
);

__PACKAGE__->meta->make_immutable;
no Any::Moose;

for my $level ( keys %$Levels ) {
    no strict "refs";
    my $level_num = $Levels->{$level};
    *{$level} = sub {
        my ($self, $msg) = @_;
        return if $level_num > $Levels->{ $self->{level} };

        my (undef, $filename, $line) = caller;
        $self->{buffer} .= sprintf("[%s] ", scalar localtime)
            if $self->{timestamp};
        $self->{buffer} .= "[$level] $msg at $filename line $line\n";
    };
}

sub flush {
    my $self = shift;
    return unless $self->{buffer};
    warn delete $self->{buffer};
}

1;

__END__

=head1 NAME

Acore::WAF::Log - log

=head1 SYNOPSIS

  use Acore::WAF::Log;
  $log = Acore::WAF::Log->new;
  $log->level('error');
  $log->error('Error message.'); # send message to STDERR

=head1 DESCRIPTION

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
