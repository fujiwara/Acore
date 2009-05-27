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
          <div class="data">
            <h3>すべてのユーザ</h3>
? for my $user ( @{ $c->stash->{all_users} } ) {
            <dl>
              <dt class="data-operation"><a href="<?= $c->uri_for('/admin_console/user_form/', { name => $user->name } ) ?>"><?= $user->name ?></a></dt>
              <dd>
                <p class="property">
                  <span class="key">Roles:</span><span class="val"><?= $user->roles | join(", ") ?></span>
                </p>
              </dd>
            </dl>
? }
          </div>
        </div>
        <div id="gamma">
          <div id="gamma-inner">
          </div>
        </div>
      </div>
    </div>
</body>
</html>
