<?
   my $c = $_[0];
   my $doc = $c->stash->{document};
   $c->stash->{title} = "View の削除完了";
?>
?= raw $c->render_part("@{[ location ]}/header.mt");
?= raw $c->render_part("@{[ location ]}/container.mt");
    <div id="pagebody">
      <div id="pagebody-inner" class="clearfix">
        <div id="alpha">
          <div id="alpha-inner">
          </div>
          <!-- /alpha -->
        </div>
        <div id="beta">

          <div id="beta-inner">
            <h2 class="icon"><div class="action_viewmag">
                <a href="<?= $c->uri_for("/@{[ location ]}/view") ?>">View の管理</a></div></h2>
          </div>
          <div class="form-container">
            <div class="result-message">
              <h2>削除されました</h2>
              <p>
                <a href="<?= $c->uri_for("/@{[ location ]}/view") ?>">一覧へ</a>
              </p>
            </div>
          </div>
          <div id="gamma">
            <div id="gamma-inner">
            </div>
          </div>
        </div>
      </div>
    </div>
?= raw $c->render_part("@{[ location ]}/container_close.mt");

