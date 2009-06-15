<?
   my $c = $_[0];
   $c->stash->{title} = "Document の管理";
   sub smart {
       joint {
           my $arg = shift;
           ref $arg eq 'ARRAY' ? "[" . join(", ", @$arg) . "]"
                               : $arg;
       };
   }
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
            <h2 class="icon"><div class="mimetype_kmultiple">Document の管理</div></h2>
            <h3><a href="<?= $c->uri_for('/admin_console/document_create_form') ?>">新規作成</a></h3>
          </div>
          <div class="data">

?=r $c->render_part('admin_console/document_serach_form.mt');

            <p>
<?
   my $offset = $c->stash->{offset};
   my $limit  = $c->stash->{limit};
   my $page   = $c->stash->{page};
   my $type   = $c->req->param('type');
   my $query  = $c->req->param('q');
?>
              <? if ( $page >= 2 ) { ?>
              <a href="<?= $c->uri_for('/admin_console/document_list', { page => $page - 1, type => $type, q => $query }) ?>">&lt;</a> |
              <? } ?>
              <?= $offset + 1 ?> 〜 <?= $offset + $limit ?>
              |
              <a href="<?= $c->uri_for('/admin_console/document_list', { page => $page + 1, type => $type, q => $query }) ?>">&gt;</a>
            </p>
            <table class="data">
              <tbody>
                <tr>
                  <th class="first">id</th><th>path</th>
? my $keys = $c->session->get('document_show_keys') || [];
? for my $key ( @$keys ) {
                  <th><?= $key ?></th>
? }
                  <th>作成日時</th>
                  <th class="last">更新日時</th>
                </tr>
? for my $doc ( @{ $c->stash->{all_documents} } ) {
                <tr>
                  <td><a href="<?= $c->uri_for('/admin_console/document_form', { id => $doc->id } ) ?>" title="<?= $doc->{title} ?>"><?= $doc->id ?></a></td>
                  <td><?= $doc->path ?></td>
? for my $key ( @$keys ) {
                  <td><?= $doc->{$key} | smart ?></td>
? }

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
