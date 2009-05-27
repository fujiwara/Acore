? my $c = $_[0]
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title><?= $c->config->{name} ?></title>
    <link rel="stylesheet" type="text/css" href="<?= $c->uri_for('/admin_console/static/css/import.css') ?>">
    <link rel="stylesheet" type="text/css" href="<?= $c->uri_for('/admin_console/static/css/form/import.css') ?>">
    <link rel="stylesheet" type="text/css" href="<?= $c->uri_for('/admin_console/static/css/icon/import.css') ?>">
    <script src="http://www.google.com/jsapi"></script>
    <script type="text/javascript"> google.load("jquery", "1.3") </script>
  </head>
