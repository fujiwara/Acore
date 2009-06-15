? my $c = $_[0]
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title><?= $c->stash->{title} || "" ?> - <?= $c->config->{name} ?> 管理コンソール</title>
    <link rel="stylesheet" type="text/css" href="<?= $c->uri_for('/admin_console/static/css/import.css') ?>">
    <link rel="stylesheet" type="text/css" href="<?= $c->uri_for('/admin_console/static/css/form/import.css') ?>">
    <link rel="stylesheet" type="text/css" href="<?= $c->uri_for('/admin_console/static/css/icon/import.css') ?>">
    <script type="text/javascript" src="<?= $c->uri_for('/admin_console/static/js/jquery-1.3.2.min.js') ?>"></script>
? if ($c->stash->{load_jquery_ui}) {
    <link type="text/css" href="<?= $c->uri_for('/admin_console/static/css/ui-lightness/jquery-ui-1.7.2.custom.css') ?>" rel="stylesheet" />
    <script type="text/javascript" src="<?= $c->uri_for('/admin_console/static/js/jquery-ui-1.7.2.custom.min.js') ?>"></script>
? }
  </head>
