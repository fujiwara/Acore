? my $c = $_[0];
uri: <?= $c->req->uri ?>
html: <?= $c->stash->{value} ?>
raw1: <?=r $c->stash->{value} ?>
raw2: <?= $c->stash->{value} | encoded_string ?>
日本語は UTF-8 で書きます
?= $c->render_part("include.mt");
