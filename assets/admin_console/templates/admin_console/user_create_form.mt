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
            <h2 class="icon"><div class="app_kuser"><a href="<?= $c->uri_for('/admin_console/user_list') ?>">ユーザの管理</a></div></h2>
          </div>
          <div class="form-container">
              <form action="<?= $c->uri_for('/admin_console/user_create_form') ?>" method="post" id="user-form">
?      if ($c->form->has_error) {
              <p class="error">
                エラーがあります
                <ul>
?          for my $msg ( @{ $c->form->{_error_ary} } ) {
                  <li><?= $msg->[0] ?> <?= $msg->[1] ?></li>
?          }
                </ul>
              </p>
?      }
?      my $user = $c->stash->{user};
                <fieldset>
                  <legend>ユーザ情報</legend>
                  <div>
                    <label for="name">Name</label>
                    <input type="text" name="name" value="" size="20" />
                  </div>
                  <div>
                    <label for="password">パスワード</label>
                    <div id="password-inputs">
                      <input type="password" name="password1" size="20"/>
                      (確認)
                      <input type="password" name="password2" size="20"/>
                    </div>
                  </div>
                  <div>
                    <label for="roles">Roles</label>
                    <div id="roles-inputs">
                      <input type="button" id="add-role-button" value="追加" />
                    <? for my $role ( qw/ Reader / ) { ?>
                      <input type="text" name="roles" value="<?= $role ?>" size="10"/>
                    <? } ?>
                    </div>
                  </div>

                </fieldset>
                <div class="buttonrow">
                  <input type="submit" value="作成する" class="button"/>
                  <input type="hidden" name="sid" value="<?= $c->session->session_id ?>"/>
                </div>
              </form>
            </div>
          </div>
          <div id="gamma">
            <div id="gamma-inner">
            </div>
          </div>
        </div>
      </div>
    </div>
    <script type="text/javascript">
      $('#add-role-button').click( function() {
        $('#roles-inputs').append(' <input type="text" name="roles" size="10"/>');
      });

    </script>
</body>
</html>
