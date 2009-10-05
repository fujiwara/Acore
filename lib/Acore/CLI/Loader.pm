package Acore::CLI::Loader;

use strict;
use warnings;
use Acore;
use Acore::WAF::ConfigLoader;
use DBI;
use Exporter "import";
our @EXPORT = qw/ acore Dump /;
use Data::Dumper;
use YAML ();

sub acore {
    my $config = shift;

    if ( $config && ref $config eq "HASH" ) {
        # use config by arguments
    }
    else {
        my $loader = Acore::WAF::ConfigLoader->new;
        $config = $loader->load($config || $ENV{CONFIG});
    }

    my $dbh = DBI->connect(@{ $config->{dsn} });
    return Acore->new({ dbh => $dbh });
}

sub Dump {
    print YAML::Dump(@_);
}

1;

__END__

__END__

=head1 NAME

Acore::CLI::Loader - easy to create Acore instance

=head1 SYNOPSIS

 use Acore::CLI::Loader;
 $acore = acore("config/foo.yaml");

 CONFIG=config/foo.yaml perl -MAcore::CLI::Loader -e 'Dump acore->search_documents({ path => "/" })'

=head1 DESCRIPTION

easy to create Acore instance shortcut module.

=head1 METHODS

=over 4

=item acore

Create Acore instance, using config (arguments hashref, string, $ENV{CONFIG}).

 acore({ dsn => [...] });
 acore("config/foo.yaml");
 acore;

=item Dump

shortcut to

 print YAML::Dump(@_);

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

YAML

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
