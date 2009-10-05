package Acore::Easy;

use strict;
use warnings;
use Acore;
use Acore::WAF::ConfigLoader;
use DBI;
use Exporter "import";
use YAML ();
use Class::Inspector;
our $Acore;
our @EXPORT = qw/ acore init Dump /;

{
    for my $sub (@{ Class::Inspector->functions("Acore") }) {
        next if $sub =~ /^_/ || $sub =~ /^[A-Z_]+$/;
        no strict "refs";
        *{"$sub"} = sub {
            acore()->$sub(@_);
        };
        push @EXPORT, $sub;
    }
}
init() if $ENV{CONFIG};

sub init {
    my $config = $_[0];

    if ( $config && ref $config eq "HASH" ) {
        # use config by arguments
    }
    else {
        my $loader = Acore::WAF::ConfigLoader->new;
        $config = $loader->load(
            $_[0] ? @_
                  : ($ENV{CONFIG}, $ENV{CONFIG_LOCAL})
        );
    }

    my $dbh = DBI->connect(@{ $config->{dsn} });
    $Acore = Acore->new({ dbh => $dbh });
}

sub acore {
    $Acore || init(@_);
}

sub Dump {
    print YAML::Dump(@_);
}

1;
__END__

=head1 NAME

Acore::Easy - easy to create Acore instance

=head1 SYNOPSIS

 use Acore::Easy;
 init("config/foo.yaml");
 Dump search_documents({ path => "/foo" });

 CONFIG=config/foo.yaml perl -MAcore::CLI::Loader -e 'Dump search_documents({ path => "/" })'

=head1 DESCRIPTION

easy to create Acore instance shortcut module.

=head1 METHODS

=over 4

=item init

Initialize Acore instance, using config (arguments hashref, string, $ENV{CONFIG}, $ENV{CONFIG_LOCAL}).

 init({ dsn => [...] });
 init("config/foo.yaml");
 init;

=item acore

Returns initialized Acore instance. If not inialized, call init().

=item Dump

shortcut to

 print YAML::Dump(@_);

=item all public methods in Acore

All Acore's public methods shortcuts is exported.

 init;  # initialize Acore instance, set to $Acore::Easy::Acore.
 @docs = search_documents({ path => "/foo" });

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

YAML

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
