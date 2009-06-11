? my $c = $_[0];
<!-- create form for <?=r $c->stash->{class} ?> -->
<fieldset>
<legend>Content</legend>
<?=r $c->req->param('form-html') ?>
</fieldset>
