? my ($c, $content) = @_;
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=<?= $c->charset ?>"/>
    <title>お問い合わせ</title>
  </head>
  <body>
    <h1>お問い合わせ</h1>
?= raw $content
  </body>
</html>
