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
            <div class="form-container">

              <h2 class="icon"><div class="mimetype_kmultiple"><a href="<?= $c->uri_for('/admin_console/document_list') ?>">Document の管理</a></div></h2>

? my $doc = $c->stash->{document};
? if (!$doc) {
              <p class="error">id = <?= $c->req->param('id') ?> の Document は存在しません</p>
? } else {
              <form action="<?= $c->uri_for('/admin_console/document_form') ?>" method="post">
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
                </fieldset>
                <fieldset>
                  <legend>Content</legend>
                  <div>
                    <label for="content">JSON</label>
<?
   my $json = JSON->new->pretty;
   my $obj = $doc->to_object;
   delete $obj->{$_} for qw/ _id _class path updated_on created_on /;
?>
                    <textarea name="content" cols="60" rows="20"><?= $json->encode($obj) ?></textarea>
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
</body>
</html>
