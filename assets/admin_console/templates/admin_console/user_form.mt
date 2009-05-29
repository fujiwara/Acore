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
              <form action="<?= $c->uri_for('/admin_console/user_form') ?>" method="post" id="user-form">
<?      if ($c->form->has_error) {
            $c->form->set_message(
               "password.dup"       => "パスワードが確認入力と一致しません",
               "password1.not_null" => "パスワードを入力してください",
               "password1.ascii"    => "パスワードは半角で入力してください",
            );
?>
              <p class="error">
?          for my $msg ( $c->form->get_error_messages ) {
                  <?= $msg ?><br/>
?          }
              </p>
?      }
?      my $user = $c->stash->{user};
                <fieldset>
                  <legend>ユーザ情報</legend>
                  <div>
                    <label for="name">Name</label>
                    <?= $user->name ?>
                    <input type="hidden" name="name" value="<?= $user->name ?>"/>
                    <? if ($user->name ne $c->user->name) { ?>
                    <input type="button" id="delete-button" value="このユーザを削除"/>
                    <? } ?>
                  </div>
                  <div>
                    <label for="password">パスワード</label>
                    <input type="button" id="change-password-button" value="変更する"/>
                    <div id="password-inputs">
                    </div>
                  </div>
                  <div>
                    <label for="roles">Roles</label>
                    <div id="roles-inputs">
                      <input type="button" id="add-role-button" value="追加" />
                    <? for my $role ( $user->roles ) { ?>
                      <input type="text" name="roles" value="<?= $role ?>" size="10"/>
                    <? } ?>
                    </div>
                  </div>

                </fieldset>
                <div class="buttonrow">
                  <input type="submit" value="更新する" class="button"/>
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
      $('#delete-button').click( function() {
        if (confirm('削除してよろしいですか?')) {
          $('#user-form').attr({'action' : '<?= $c->uri_for('/admin_console/user') | js ?>'});
          $('#user-form').append('<input type="hidden" name="_method" value="DELETE"/>');
          $('#user-form').submit();
        }
      })

      $('#change-password-button').click( function() {
        $('#password-inputs').append('<input type="password" name="password1" value="" /> (確認)<input type="password" name="password2" value="" />');
        $('#change-password-button').hide();
      });

      $('#add-role-button').click( function() {
        $('#roles-inputs').append('<input type="text" name="roles" size="10"/>');
      });

    </script>
</body>
</html>
