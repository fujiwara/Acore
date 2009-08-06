? my $c = $_[0];
<!-- create form for <?= raw $c->stash->{class} ?> -->
<fieldset>
<legend>Content</legend>
<?= raw $c->req->param('form-html') ?>
</fieldset>
