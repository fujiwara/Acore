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
);

has timestamp => (
    is      => "rw",
    default => 1,
);

has caller => (
    is      => "rw",
    default => 0,
);

has disabled => (
    is      => "rw",
    default => 0,
);

has file => (
    is => "rw",
);

__PACKAGE__->meta->make_immutable;
no Any::Moose;

for my $level ( keys %$Levels ) {
    no strict "refs";
    my $level_num = $Levels->{$level};
    *{$level} = sub {
        my ($self, $msg, @args) = @_;
        return if $level_num > $Levels->{ $self->{level} };
        return if $self->{disabled};

        $self->{buffer} .= sprintf("[%s] ", scalar localtime(time) )
            if $self->{timestamp};

        $msg = sprintf $msg, @args
            if @args;
        if ($self->{caller}) {
            my (undef, $filename, $line) = caller;
            $self->{buffer} .= "[$level] $msg at $filename line $line\n";
        }
        else {
            $self->{buffer} .= "[$level] $msg \n";
        }
    };
}

sub flush {
    my $self = shift;
    return unless $self->{buffer};
    return if $self->{disabled};
    if ( defined $self->{file} ) {
        local *STDERR;
        open *STDERR, ">>", $self->{file}
            or croak("Can't open log output $self->{file} $!");
        warn delete $self->{buffer};
    }
    else {
        warn delete $self->{buffer};
    }
}

1;

__END__

=head1 NAME

Acore::WAF::Log - log module

=head1 SYNOPSIS

  use Acore::WAF::Log;
  $log = Acore::WAF::Log->new;
  $log->level('error');
  $log->error('Error message.'); # send message to STDERR
  $log->error('message %s %d', "string", 12345); # format by sprintf

  $log->file('/path/to/log_file'); # output log to file.

=head1 DESCRIPTION

=head1 LOG LEVELS

Default level is "info".

=over 4

=item emerge

=item alert

=item critical

=item error

=item warning

=item notice

=item info

=item debug

=back

=head1 METHODS

=over 4

=item level

Get or set log level.

 $log->level;
 $log->level('debug');

=item timestamp

Flag to add timestamp in log message.

Default: 1

=item caller

Flag to add caller info(file, line) in log message.

Default: 0

=item flush

Flush buffer to STDERR or file.

=item file

Filename to output log on flush.

Default: STDERR

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
