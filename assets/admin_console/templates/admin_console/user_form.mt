<?
  my $c = $_[0];
  $c->stash->{title} = "ユーザの管理";
  $c->stash->{load_jquery_ui} = 1;
?>
?=r $c->render_part("@{[ location ]}/header.mt");
?=r $c->render_part("@{[ location ]}/container.mt");
    <div id="pagebody">
      <div id="pagebody-inner" class="clearfix">
        <div id="alpha">
          <div id="alpha-inner">
          </div>
          <!-- /alpha -->
        </div>
        <div id="beta">
          <div id="beta-inner">
            <h2 class="icon"><div class="app_kuser"><a href="<?= $c->uri_for("/@{[ location ]}/user_list") ?>">ユーザの管理</a></div></h2>
          </div>
?       if ( $c->flash->get('user_saved') ) {
?=r         $c->render_part("@{[ location ]}/notice.mt", '保存されました');
?       }

          <div class="form-container">
              <form action="<?= $c->uri_for("/@{[ location ]}/user_form") ?>" method="post" id="user-form">
<?      if ($c->form->has_error) {
            $c->form->set_message(
               "password.dup"       => "パスワードが確認入力と一致しません",
               "password1.not_null" => "パスワードを入力してください",
               "password1.ascii"    => "パスワードは半角で入力してください",
            );
?>
              <div class="errors">
?          for my $msg ( $c->form->get_error_messages ) {
                  <?= $msg ?><br/>
?          }
              </div>
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

                  <? for my $attr ( $user->attributes ) { ?>
                  <div id="attr-<?= $attr ?>-container">
                    <label for="_attr_<?= $attr ?>"><?= $attr ?></label>
                    <div id="<?= $attr ?>-inputs">
                      <input type="text" name="_attr_<?= $attr ?>" value="<?= $user->attr($attr) ?>" size="30"/>
                      <a href="#" id="delete-attr-<?= $attr ?>" rel="<?= $attr ?>" class="delete-attr">削除</a>
                    </div>
                  </div>
                  <? } ?>

                  <div id="add-new-attr-container"></div>

                  <div>
                    <label>
                      <input type="text" id="new-attr-name" size="10"/>
                    </label>
                    <div>
                      <input type="button" value="属性追加" id="new-attr-button" />
                      <span id="new-attr-error">属性は半角英数 (先頭はアルファベットのみ) で入力してください)</span>
                    </div>
                  </div>

                </fieldset>
                <div class="buttonrow">
                  <input type="hidden" id="remove-attrs" name="remove_attrs"/>
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
    <?=r $c->render_part("@{[ location ]}/flash_message.js") ?>

      $('#delete-button').click( function() {
        if (confirm('削除してよろしいですか?')) {
          $('#user-form').attr({'action' : '<?= $c->uri_for("/@{[ location ]}/user") | js ?>'});
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

      $('#new-attr-button').click( function() {
        var name = $('#new-attr-name').val();
        if ( !name
          || !name.match(/^[a-zA-Z][a-zA-Z0-9_]*$/)
          || $('#attr-'+name+'-container')[0])
        {
          $('#new-attr-error').show();
          return false;
        }
        var html = '<div id="attr-ATTR-container"><label for="_attr_ATTR">ATTR</label>'
                 + '<div id="ATTR-inputs">'
                 + '<input type="text" name="_attr_ATTR" value="" size="30"/>'
                 + ' <a href="#" id="delete-attr-ATTR">削除</a>'
                 + '</div></div>';
        html = html.replace(/ATTR/g, name);
        $('#add-new-attr-container').append(html);
        $('#delete-attr-'+name).click( function() {
          $('#attr-'+name+'-container').remove();
        });
        $('#new-attr-name').val("");
        $('#new-attr-error').hide();
      });

      $('a.delete-attr').each( function() {
        $(this).click( function () {
          var name = $(this).attr("rel");
          $('#remove-attrs').val( $('#remove-attrs').val() + "," + name );
          $('#attr-'+name+'-container').remove();
          return false;
        });
      });
    </script>
?=r $c->render_part("@{[ location ]}/container_close.mt");

