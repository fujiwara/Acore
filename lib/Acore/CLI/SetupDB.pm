package Acore::CLI::SetupDB;

use strict;
use warnings;
use Getopt::Long;
use DBI;
use Acore::Storage;

sub run {
    my ( $dsn, $user, $password, $usage );
    my $result = GetOptions(
        "dsn=s"      => \$dsn,
        "username=s" => \$user,
        "password=s" => \$password,
        "help"       => \$usage,
    );
    if ($usage || !$dsn) {
        usage();
        exit;
    }
    my $dbh = DBI->connect(
        $dsn, $user, $password,
        { RaiseError => 1, AutoCommit => 0 },
    );
    my $storage = Acore::Storage->new({ dbh => $dbh });
    $storage->setup();
    $dbh->commit;
    1;
}

sub usage {
    print <<"    _END_OF_USAGE_";
 $0 --dsn=DSN --username=USERNAME --password=PASSWORD

 options
   --help: show this usage.
    _END_OF_USAGE_

}

1;