# -*- mode:perl -*-
use strict;
use Test::More tests => 10;
use Test::Exception;
use Data::Dumper;
my $dbh = require t::connect_db;

BEGIN {
    use_ok 'Acore';
    use_ok 'Acore::Document::File';
};

{
    my $ac = Acore->new({ dbh => $dbh });
    $ac->setup_db;

    isa_ok $ac => "Acore";

    mkdir "t/tmp";
    my $file = Acore::Document::File->new({
        path         => "/foo/bar/baz",
        file_path    => "t/tmp/$$.txt",
        content_type => "text/plain",
    });

    my $doc = $ac->put_document($file);
    {
        my $fh  = $doc->openw;
        ok $fh;
        $fh->print("textfile");
    }
    isa_ok $doc           => "Acore::Document::File";
    is $doc->file_path    => "t/tmp/$$.txt", "file path ok";
    is $doc->content_type => "text/plain";
    is $doc->slurp        => "textfile";
    ok $doc->stat->mtime <= time;
    ok $doc->remove;
}

$dbh->commit;
