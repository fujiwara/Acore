? my $c        = shift;
? my $location = location();
? my $id       = $c->flash->get("id") || $c->stash->{id} || $c->req->param("id");
? $c->renderer->wrapper_file("$location/wrapper.mt", $c)->(sub {
<p>
  お問い合わせを受け付けました。
</p>
<p>
? my @id = ($id =~ /(.{1,4})/g);
  お問い合わせ番号: <?= join("-", @id) ?>
</p>
? });