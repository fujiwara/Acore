? my $c        = shift;
? my $location = location();
? my $id       = $c->flash->get("id") || $c->stash->{id} || $c->req->param("id");
<p>
  お問い合わせを受け付けました。
</p>
<p>
  お問い合わせ番号: <?= $id ?>
</p>
