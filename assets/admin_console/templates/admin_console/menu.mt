? my $c = $_[0];
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
            <div class="menu">
              <h2>メニュー</h2>
              <div class="item">
                <a class="app_kuser" href="<?= $c->uri_for('/admin_console/user_list') ?>">ユーザの管理</a>
              </div>
              <div class="item">
                <a class="mimetype_kmultiple" href="<?= $c->uri_for('/admin_console/document_list') ?>">Document の管理</a>
              </div>
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
</body>
</html>