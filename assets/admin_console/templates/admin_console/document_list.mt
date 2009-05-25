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
            <h2 class="icon"><div class="app_kuser">Document の管理</div></h2>
          </div>
          <div class="data">
            <h3>すべての Document</h3>
            <table class="data">
              <tbody>
                <tr>
                  <th class="first">id</th><th>path</th><th>作成日時</th><th>更新日時</th>
                </tr>
? use Data::Dumper;
? for my $doc ( @{ $c->stash->{all_documents} } ) {
                <tr>
                  <td><a href="<?= $c->uri_for('/admin_console/document_form', { id => $doc->id } ) ?>"><?= $doc->id ?></a></td>
                  <td><?= $doc->path ?></td>
                  <td><?= $doc->created_on ?></td>
                  <td><?= $doc->updated_on ?></td>
                </tr>
? }
              </tbody>
            </table>
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