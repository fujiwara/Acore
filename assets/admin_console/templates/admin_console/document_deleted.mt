<?
   my $c = $_[0];
   my $doc = $c->stash->{document};
   $c->stash->{title} = "Document の削除完了";
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
            <div class="form-container">

              <h2 class="icon"><div class="mimetype_kmultiple"><a href="<?= $c->uri_for('/admin_console/document_list') ?>">Document の管理</a></div></h2>

?=r $c->render_part('admin_console/document_serach_form.mt');

              <div>
                <h3>削除されました</h3>
              </div>
              <div>
                <a href="<?= $c->uri_for('/admin_console/document_list') ?>">一覧へ</a>
              </div>

            </div>
          </div>
          <div id="gamma">
            <div id="gamma-inner">
            </div>
          </div>
        </div>
      </div>
    </div>
</body>
</html>
