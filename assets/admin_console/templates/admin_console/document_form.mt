? my $c = $_[0];
? my $doc = $c->stash->{document};
? $c->stash->{title} = "Document の編集 - " . ($doc && $doc->{title} or "" );
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

? if (!$doc) {
              <p class="error">id = <?= $c->req->param('id') ?> の Document は存在しません</p>
? } else {
              <form action="<?= $c->uri_for('/admin_console/document_form') ?>" method="post" id="document-form">
?      if ($c->form->has_error) {
              <p class="error">
                エラーがあります
                <ul>
?          for my $msg ( @{ $c->form->{_error_ary} } ) {
                  <li><?= $msg->[0] ?> <?= $msg->[1] ?></li>
?          }
                </ul>
              </p>
?      }
                <fieldset>
                  <legend>Meta info</legend>
                  <div>
                    <label for="id">id</label>
                    <?= $doc->id ?>
                    <input type="hidden" name="id" value="<?= $doc->id ?>"/>
                    <input type="button" id="delete-button" value="この Document を削除"/>
                  </div>
                  <div>
                    <label for="path">path</label>
                    <input size="40" type="text" name="path" value="<?= $doc->path ?>"/>
                  </div>
                  <div>
                    <label for="created_on">作成日時</label>
                    <?= $doc->created_on ?>
                  </div>
                  <div>
                    <label for="updated_on">更新日時</label>
                    <?= $doc->updated_on ?>
                  </div>
                  <div>
                    <label for="class">Class</label>
                    <?= $doc->{_class} ?>
                  </div>
                  <div>
                    <label for="class">Content-Type</label>
                    <input type="text" name="content_type" value="<?= $doc->content_type ?>" size="20" />
                  </div>
                </fieldset>
                <fieldset>
                  <legend>Content</legend>
<?
   require YAML;
   my $obj = $doc->to_object;
   delete $obj->{$_} for qw/ id _id _class content_type path updated_on created_on /;
?>
                  <div>
                    <? if ($c->stash->{yaml_error_message}) { ?>
                    <p class="error">
                    <?=r $c->stash->{yaml_error_message} | html | html_line_break ?>
                    </p>
                    <? } ?>
                    <label for="content">YAML</label>
                    <textarea name="content" cols="60" rows="20"><?= YAML::Dump($obj) ?></textarea>
                  </div>
                </fieldset>
                <div class="buttonrow">
                  <input type="submit" value="更新する" class="button"/>
                  <input type="hidden" name="sid" value="<?= $c->session->session_id ?>"/>
                </div>
              </form>
? }
            </div>
          </div>
          <div id="gamma">
            <div id="gamma-inner">
            </div>
          </div>
        </div>
      </div>
    </div>
    <script type="text/javascript">
      $('#delete-button').click( function() {
        if (confirm('削除してよろしいですか?')) {
          $('#document-form').attr({'action' : '<?= $c->uri_for('/admin_console/document') | js ?>'});
          $('#document-form').append('<input type="hidden" name="_method" value="DELETE"/>');
          $('#document-form').submit();
        }
      })
    </script>
</body>
</html>
