? my $c = shift;
<ul class="jqueryFileTree" style="display: none;">
? foreach my $dir (sort @{ $c->stash->{folders} } ) {
    <li class="directory collapsed"><a href="#" rel="<?= $dir ?>/"><?= $dir ?></a></li>
? }
? foreach my $file (sort @{ $c->stash->{files} }) {
?    $file->basename =~ /\.(.+)$/;
?    my $ext = lc($1);
    <li class="file ext_<?= $ext ?>"><a href="#" rel="<?= $file ?>"><?= $file->basename ?></a></li>
? }
</ul>
