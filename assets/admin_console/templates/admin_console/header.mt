? my $c = $_[0]
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
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
?   if ($c->config->{admin_console}->{css_path}) {
    <link type="text/css" href="<?= $c->uri_for($c->config->{admin_console}->{css_path}) ?>" rel="stylesheet" />
?   }
    <style type="text/css">
      .flash-message {
        border: 1px solid #fda;
        background-color: #ffd;
        padding-left: 1em;
        width: 40%;
      }
      .flash-message p {
        padding: 0.5em;
        margin: 0;
      }
    </style>
  </head>
<body>
