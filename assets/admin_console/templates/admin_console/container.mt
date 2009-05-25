? my $c = $_[0];
<div id="container">
  <div id="container-inner">
    <div id="header">
      <div id="header-inner">
      <h1><?= $c->config->{name} ?> Admin console</h1>
      <div id="header-navi">
        <ul id="global-navi" class="welcome-message">
          <li>Welcome to <?= $c->config->{name} ?>!</li>
        </ul>
        <? if ($c->user) { ?>
        <ul id="remote-navi">
          <li>こんにちは <?= $c->user->name ?> さん</li>
          <li><a href="<?= $c->uri_for('/admin_console/logout') ?>">ログアウトする</a></li>
        </ul>
        <ul id="bread-crumb-navi">
          <li><a href="<?= $c->uri_for('/admin_console/menu') ?>">menu</a>/</li>
        </ul>
        <? } ?>
      </div>
      <!-- /header-inner -->
      </div>
    <!-- /header -->
    </div>
