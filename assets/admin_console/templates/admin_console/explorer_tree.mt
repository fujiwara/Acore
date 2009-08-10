? my $c = shift;
? my $root = $c->stash->{root};
<ul class="jqueryFileTree" style="display: none;">
? foreach my $dir (sort @{ $c->stash->{folders} } ) {
?    (my $d = $dir) =~ s{^\Q$root\E}{};
    <li class="directory collapsed"><a href="#" rel="<?= $d ?>/"><?= @{ $dir->{dirs} }[-1] ?></a></li>
? }
? foreach my $file (sort @{ $c->stash->{files} }) {
?    $file->basename =~ /\.(.+)$/;
?    my $ext = lc($1);
?    (my $f   = $file) =~ s{^\Q$root\E}{};
    <li class="file ext_<?= $ext ?>"><a href="#" rel="<?= $f ?>"><?= $file->basename ?></a></li>
? }
</ul>
