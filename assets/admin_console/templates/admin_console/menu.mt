<?
  my $c = $_[0];
  $c->stash->{title} = "Menu";
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
            <div class="menu">
              <h2>メニュー</h2>
              <div class="item">
                <a class="app_kuser" href="<?= $c->uri_for("/@{[ location ]}/user_list") ?>">ユーザの管理</a>
              </div>
              <div class="item">
                <a class="mimetype_kmultiple" href="<?= $c->uri_for("/@{[ location ]}/document_list") ?>">Document の管理</a>
              </div>

              <div class="item">
                <a class="mimetype_source" href="<?= $c->uri_for("/@{[ location ]}/doc_class") ?>">Document Class の作成</a>
              </div>

              <div class="item">
                <a class="action_db_add" href="<?= $c->uri_for("/@{[ location ]}/upload_document") ?>">Document の一括投入</a>
              </div>

<? unless ( $c->config->{@{[ location ]}}->{disable_eval_functions} ) { ?>
              <div class="item">
                <a class="action_viewmag" href="<?= $c->uri_for("/@{[ location ]}/view") ?>">View の管理</a>
              </div>

              <div class="item">
                <a class="action_run" href="<?= $c->uri_for("/@{[ location ]}/convert_all") ?>">Document の一括置換</a>
              </div>
<? } ?>
              <!-- /menu -->
            </div>
          </div>
        </div>
        <div id="gamma">
          <div id="gamma-inner">
          </div>
        </div>
      </div>
    </div>
?=r $c->render_part("@{[ location ]}/container_close.mt");

