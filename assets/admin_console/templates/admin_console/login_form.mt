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
              <form class="login" action="<?= $c->uri_for("/@{[ location ]}/login_form") ?>" method="post">
                <fieldset>
                  <legend>ログインしてください</legend>
<?
   if ($c->form->has_error) {
       $c->form->set_message(
           { "login.failed" => "ログインに失敗しました" },
       );
?>
                  <p class="error">
?                 for my $msg ( $c->form->get_error_messages ) {
                  <?= $msg ?><br/>
?                 }
                  </p>
? }
                  <div>
                    <label for="uname">ユーザ名:</label>
                    <input type="text" name="name" value="" size="20">
                  </div>
                  <div>
                    <label for="pw">パスワード:</label>
                    <input type="password" name="password" value="" size="20">
                  </div>
                  <br/>
                </fieldset>
                <div class="buttonrow">
                  <input type="submit" value="ログイン" class="button">
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

