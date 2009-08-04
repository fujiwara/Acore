? my $c = $_[0];
?=r $c->render_part("@{[ location ]}/header.mt");
?=r $c->render_part("@{[ location ]}/container.mt");
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
                  <legend>管理ユーザ <?= $c->req->param('name') ?> を作成しました</legend>
                  <p>
                    <a href="<?= $c->uri_for("/@{[ location ]}/login_form") ?>">ログインしてください</a>
                  </p>
                </fieldset>
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
?=r $c->render_part("@{[ location ]}/container_close.mt");

