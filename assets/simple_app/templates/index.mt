? my $c = $_[0]
<html>
<body>
<h1>index</h1>
root : <?= $c->config->{root} ?><br/>
uri : <?= $c->req->uri ?>
</body>
</html>
