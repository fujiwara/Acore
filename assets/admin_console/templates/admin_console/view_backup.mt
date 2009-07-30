? my $c     = shift;
? my $views = $c->stash->{all_views};
? local $Data::Dumper::Indent = 1;
#
# restore_views.pl for <?=r $c->config->{name} ?>
#
use strict;
use warnings;
use Acore;
use DBI;
use JSON;
use utf8;

my <?=r Data::Dumper->Dump([$c->config->{dsn}], ["dsn"]) ?>
my $dbh     = DBI->connect(@$dsn) or die DBI->errstr;
my $acore   = Acore->new({ dbh => $dbh });
my $backend = $acore->storage->document;
my $views   = JSON->new->decode( do { local $/; <DATA> } );

$dbh->begin_work;
for my $view ( @$views ) {
    print "restore view: $view->{id}\n";
    $view->{_id} = delete $view->{id};
    $backend->put( $view );
    $backend->create_view( $view->{_id}, $view );
}
$dbh->commit;
$dbh->disconnect;

print "done.\n";
exit;

__DATA__
?=r JSON->new->pretty->encode($views);
