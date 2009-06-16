<?
   my $c = $_[0];
   require YAML;
   $c->stash->{title} = "Document の一括投入";
   $c->stash->{load_jquery_ui} = 1;
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
            <h2 class="icon"><div class="action_db_add">
                Document の一括投入</div></h2>
          </div>
          <div class="form-container">
            <form action="<?= $c->uri_for('/admin_console/upload_document') ?>" method="post" enctype="multipart/form-data">
?      if ($c->form->has_error) {
               <div class="errors">
                <p><em>下記の項目の入力にエラーがあります。</em></p>
                <ul>
?          for my $msg ( @{ $c->form->{_error_ary} } ) {
                  <li><?= $msg->[0] ?> <?= $msg->[1] ?></li>
?          }
                </ul>
              </div>
?      }

?      if ($c->stash->{notice}) {
               <div class="notice">
                 <p><?= $c->stash->{notice} ?></p>
               </div>
?      }
              <fieldset>
                <legend>YAML</legend>
                <div>
                  <label for="file">アップロードファイル (YAML形式)</label>
                  <input type="file" size="30" name="file" />
                </div>
              <div class="buttonrow">
                <input type="submit" value="投入する" class="button" id="submit-button"/>
                <input type="hidden" name="sid" value="<?= $c->session->session_id ?>"/>
              </div>
            </form>
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
