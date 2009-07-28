# -*- mode:perl -*-
use strict;
use Test::More tests => 15;
use Test::Exception;
use Data::Dumper;
use utf8;
use Path::Class qw/ file /;

package FileDocument;
use Any::Moose;
extends 'Acore::Document';
has attachment_root_dir => (
    is      => "rw",
    default => "t/tmp",
);
with 'Acore::Document::Role::AttachmentFile';

package main;

BEGIN {
    use_ok 'Acore';
    use_ok 'Acore::Document';
};
{
    my $doc = FileDocument->new;
    my $file = file("t/tmp/foo.txt");
    $file->openw->print("foo\nbar\n");
    my $added = $doc->add_attachment_file($file);
    isa_ok $added, "Path::Class::File";
    my $obj = $doc->to_object;
    is_deeply $obj->{attachment_files} => ["t/tmp/foo.txt"];

    my $newdoc = Acore::Document->from_object($obj);
    isa_ok $newdoc => "FileDocument";
    is_deeply $newdoc->attachment_files => [ $file ];

    file("t/tmp/bar.txt")->openw->print("bar\nbaz\n");
    my $fh = file("t/tmp/bar.txt")->openr;
    $newdoc->add_attachment_file($fh);

    is file("t/tmp/2.dat")->slurp => "bar\nbaz\n";

    $fh = file("t/tmp/bar.txt")->openr;
    $newdoc->add_attachment_file($fh => "xxx.txt");
    is file("t/tmp/xxx.txt")->slurp => "bar\nbaz\n";

    throws_ok { $newdoc->add_attachment_file("xxx") } qr/requires/;

    ok $newdoc->remove_attachment_file(1);
    is_deeply $newdoc->attachment_files => [
        file("t/tmp/foo.txt"),
        file("t/tmp/xxx.txt"),
    ];
    ok !-e file("t/tmp/2.dat");

    ok $newdoc->remove_attachment_file( $newdoc->attachment_files->[0] );
    is_deeply $newdoc->attachment_files => [ file("t/tmp/xxx.txt") ];
    ok !-e file("t/tmp/foo.dat");
}

