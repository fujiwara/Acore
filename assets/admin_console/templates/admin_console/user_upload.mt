<?
  my $c = $_[0];
  $c->stash->{title} = "ユーザの管理";
?>
?=r $c->render_part("admin_console/header.mt");
?=r $c->render_part("admin_console/container.mt");
    <div id="pagebody">
      <div id="pagebody-inner" class="clearfix">
        <div id="alpha">
          <div id="alpha-inner">
          </div>
          <!-- /alpha -->
        </div>
        <div id="beta">
          <div id="beta-inner">
            <h2 class="icon"><div class="app_kuser">ユーザの管理</div></h2>
          </div>
          <div class="form-container">
            <h3><?= $c->stash->{imported} ?> ユーザが登録・更新されました</h3>
            <p>
              <a href="<?= $c->uri_for('/admin_console/user_list') ?>">ユーザ一覧へ</a>
            </p>
          </div>
          <div id="gamma">
            <div id="gamma-inner">
            </div>
          </div>
        </div>
      </div>
    </div>
</body>
</html>
