? my $c = $_[0];
?=r $c->render_part("admin_console/header.mt");
?=r $c->render_part("admin_console/container.mt");

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
              <form class="login" action="<? $c->uri_for('/admin_console/setup_at_first') ?>" method="post">
                <fieldset>
                  <legend>最初の管理ユーザを作成します</legend>
<?
   if ($c->stash->{user_exists}) {
?>
                  <p class="error">すでにユーザが存在します。</p>
                  <p>
                    <a href="<?= $c->uri_for('/admin_console/login_form') ?>">ログインしてください</a>
                  </p>
? } elsif ($c->form->has_error) {
                  <p class="error">エラーがあります</p>
                  <ul>
?                 for my $msg ( @{ $c->form->{_error_ary} } ) {
                    <li><?= $msg->[0] ?> <?= $msg->[1] ?></li>
?                 }
                  </ul>
? }
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
</body>
</html>
