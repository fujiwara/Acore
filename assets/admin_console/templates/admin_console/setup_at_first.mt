? my $c = $_[0];
?= raw $c->render_part("@{[ location ]}/header.mt");
?= raw $c->render_part("@{[ location ]}/container.mt");

    <div id="pagebody">
      <div id="pagebody-inner" class="clearfix">
        <div id="alpha">
          <div id="alpha-inner">
            <!-- /alpha-inner -->
          </div>
          <!-- /alpha -->
        </div>
        <div id="beta">
          <div id="beta-inner">
            <div class="form-container">
              <form class="login" action="<? $c->uri_for("/@{[ location ]}/setup_at_first") ?>" method="post">
                <fieldset>
                  <legend>最初の管理ユーザを作成します</legend>
? if ($c->stash->{user_exists}) {
                  <p class="error">すでにユーザが存在します。</p>
                  <p>
                    <a href="<?= $c->uri_for("/@{[ location ]}/login_form") ?>">ログインしてください</a>
                  </p>
<? } else {
       if ($c->form->has_error) {
           $c->form->set_message({
               "name.not_null"      => "ユーザ名を入力してください",
               "name.ascii"         => "ユーザ名は半角で入力してください",
               "password1.not_null" => "パスワードを入力してください",
               "password1.ascii"    => "パスワードは半角で入力してください",
               "password.dup"       => "パスワードの確認入力が一致しません",
           });
?>
                  <p class="error">エラーがあります</p>

?          for my $msg ( $c->form->get_error_messages ) {
                  <?= $msg ?><br/>
?          }
?     }
                  <div>
                    <label for="uname">ユーザ名:</label>
                    <input type="text" name="name" value="" size="20">
                  </div>
                  <div>
                    <label for="pw">パスワード:</label>
                    <input type="password" name="password1" value="" size="20">
                  </div>
                  <div>
                    <label for="pw">パスワード(確認入力):</label>
                    <input type="password" name="password2" value="" size="20">
                  </div>
                  <br/>
? }
                </fieldset>
                <div class="buttonrow">
                  <input type="submit" value="ユーザを作成する" class="button">
                </div>
              </form>
              <!-- /form-container -->
            </div>
            <!-- /beta-inner -->
          </div>
          <!-- /beta -->
        </div>
        <div id="gamma">
          <div id="gamma-inner">
          </div>
        </div>
      </div>
    </div>
?= raw $c->render_part("@{[ location ]}/container_close.mt");

