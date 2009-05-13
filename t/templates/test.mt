? my $c = $_[0];
uri: <?= $c->req->uri ?>
html: <?= $c->stash->{value} ?>
raw: <?=r $c->stash->{value} ?>
日本語は UTF-8 で書きます
?= $c->render_part("include.mt");
