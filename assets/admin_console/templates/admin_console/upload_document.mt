<?
   my $c = $_[0];
   require YAML;
   $c->stash->{title} = "Document の一括投入";
   $c->stash->{load_jquery_ui} = 1;
?>
?= r $c->render_part("@{[ location ]}/header.mt");
?= r $c->render_part("@{[ location ]}/container.mt");
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
            <form action="<?= $c->uri_for("/@{[ location ]}/upload_document") ?>" method="post" enctype="multipart/form-data" id="upload-form">
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
?= r        $c->render_part("@{[ location ]}/notice.mt", $c->stash->{notice});
            <p>
              <a href="<?= $c->uri_for("/@{[ location ]}/document_list") ?>">一覧へ</a>
            </p>
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
                <div id="uploading-icon" style="display: none"><img src="<?= $c->uri_for("/@{[ location ]}/static/images/uploading.gif") ?>" alt="uploading..."/></div>
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
    <script type="text/javascript">
      $(document).ready( function() {
        $('#upload-form').submit( function() {
          $('#submit-button').hide();
          $('#uploading-icon').show();
        });
      });
    </script>
?= r $c->render_part("@{[ location ]}/container_close.mt");
