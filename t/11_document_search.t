# -*- mode:perl -*-
use strict;
use Test::More tests => 9;
use Test::Exception;
use Data::Dumper;
use t::Cache;

BEGIN {
    use_ok 'Acore';
    use_ok 'Acore::Document';
};

{
    my $dbh = do "t/connect_db.pm";
    my $ac  = Acore->new({ dbh => $dbh });
    $ac->setup_db;

    for my $t ([qw/ dog cat /], [qw/ cat more less /], [qw/ cat cdr cnt /]) {
        $ac->put_document(
            Acore::Document->new({
                path => "/" . join("/", @{$t}),
                body => "tagged as @{$t}",
                tags => $t,
            })
        );
    }

    my @docs = $ac->search_documents({ tag => "cat" });
    is scalar @docs => 3;
    like $_->{body} => qr{cat} for @docs;

    @docs = $ac->search_documents({ tag => "dog" });
    is scalar @docs => 1;
    is $docs[0]->{body} => "tagged as dog cat";
    is_deeply $docs[0]->tags => [qw/ dog cat /];

    $dbh->commit;
}

