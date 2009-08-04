<?
   my $c = $_[0];
   $c->stash->{title}          = "Document の管理";
   $c->stash->{load_jquery_ui} = 1;
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
            <h2 class="icon"><div class="mimetype_kmultiple">Document の管理</div></h2>
            <h3 class="icon"><div class="mimetype_document_s"><a href="<?= $c->uri_for("/@{[ location ]}/document_create_form") ?>">新規作成</a></div></h3>
            <h3 class="icon"><div class="action_db_add_s"><a href="<?= $c->uri_for("/@{[ location ]}/upload_document") ?>">一括投入</a></div></h3>
          </div>
          <div class="data">

?=r $c->render_part("@{[ location ]}/document_serach_form.mt");

            <p>
<?
   my $offset = $c->stash->{offset};
   my $limit  = $c->stash->{limit};
   my $page   = $c->stash->{page};
   my $type   = $c->req->param('type');
   my $query  = $c->req->param('q');
   my $match  = $c->req->param('match');
?>
              <? if ( $page >= 2 ) { ?>
              <a href="<?= $c->uri_for("/@{[ location ]}/document_list", { page => $page - 1, type => $type, q => $query, match => $match, limit => $limit }) ?>">&lt;</a> |
              <? } ?>
              <?= $offset + 1 ?> 〜 <?= $offset + $limit ?>
              |
              <a href="<?= $c->uri_for("/@{[ location ]}/document_list", { page => $page + 1, type => $type, q => $query, match => $match, limit => $limit }) ?>">&gt;</a>
            </p>
            <form action="<?= $c->uri_for("/@{[ location ]}/document") ?>" method="post" id="delete-form">
              <input type="hidden" name="sid" value="<?= $c->session->session_id ?>"/>
            <input type="button" value="チェックした Document を削除" class="delete-button" />
            <table class="data">
              <tbody>
                <tr>
                  <th class="first" style="width: 1em;">
                    <span id="toggle-all-check">＋</span>
                  </th>
                  <th>id</th>
                  <th>path</th>
? my $keys = $c->session->get('document_show_keys') || [];
? for my $key ( @$keys ) {
                  <th><?= $key ?></th>
? }
                  <th>作成日時</th>
                  <th class="last">更新日時</th>
                </tr>
? for my $doc ( @{ $c->stash->{all_documents} } ) {
                <tr>
                  <td><input type="checkbox" name="id" value="<?= $doc->id ?>" class="document-id-check"/></td>
                  <td><a href="<?= $c->uri_for("/@{[ location ]}/document_form", { id => $doc->id } ) ?>" title="<?= $doc->{title} ?>"><?= $doc->id ?></a></td>
                  <td><?= $doc->path ?></td>
? for my $key ( @$keys ) {
                  <td><?= $doc->param($key) | json ?></td>
? }

                  <td><?= $doc->created_on ?></td>
                  <td><?= $doc->updated_on ?></td>
                </tr>
? }
              </tbody>
            </table>
            <input type="button" value="チェックした Document を削除" class="delete-button" />
            </form>
            <p>
              <? if ( $page >= 2 ) { ?>
              <a href="<?= $c->uri_for("/@{[ location ]}/document_list", { page => $page - 1, type => $type, q => $query, match => $match, limit => $limit }) ?>">&lt;</a> |
              <? } ?>
              <?= $offset + 1 ?> 〜 <?= $offset + $limit ?>
              |
              <a href="<?= $c->uri_for("/@{[ location ]}/document_list", { page => $page + 1, type => $type, q => $query, match => $match, limit => $limit }) ?>">&gt;</a>
            </p>
          </div>
        </div>
        <div id="gamma">
          <div id="gamma-inner">
          </div>
        </div>
      </div>
    </div>

    <div id="delete-dialog" title="確認">
      <span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>
      選択されたドキュメントを削除しますか?
    </div>
    <script type="text/javascript">
    $(document).ready( function(){
      $('#delete-dialog').dialog({
        bgiframe: true,
        resizable: false,
        height:180,
        modal: true,
        overlay: {
          backgroundColor: '#000',
          opacity: 0.5
        },
        buttons: {
          '削除する': function() {
             $(this).dialog('close');
             $('#delete-form')
               .append('<input type="hidden" name="_method" value="DELETE" />')
               .submit();
          },
          Cancel: function() {
             $(this).dialog('close');
          }
        }
      }).dialog('close');

      $('input.delete-button').click( function () {
         $('#delete-dialog').dialog('open');
      });

      var show_delete_button = function () {
        if ( $('input.document-id-check:checked')[0] ) {
          $('input.delete-button').show();
        }
        else {
          $('input.delete-button').hide();
        }
      }
      show_delete_button();

      $('input.document-id-check').click(show_delete_button);

      $('#toggle-all-check')
        .css({ cursor: "pointer" })
        .click( function() {
           var flag = false;
           if ($(this).html() == '＋') {
             flag = true;
             $(this).html('&minus;');
           }
           else {
             $(this).html('＋');
           }
           $('input.document-id-check').attr("checked", flag);
           show_delete_button();
        });
    });
    </script>
?=r $c->render_part("@{[ location ]}/container_close.mt");

