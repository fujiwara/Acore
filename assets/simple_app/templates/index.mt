? my $c = $_[0]
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>SimpleApp</title>
    <link rel="icon" href="favicon.ico" type="image/png">
  </head>
  <body>
    <h1>SimpleApp Index</h1>
    <p>
      root : <?= $c->config->{root} ?><br/>
      uri : <?= $c->req->uri ?><br/>
      counter in session : <?= $c->session->{counter} ?><br/>
    </p>
  </body>
</html>