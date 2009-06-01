<?
   my $c = $_[0];
   $c->stash->{title} = "Document の作成";
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
              <h3>新規作成</h3>

              <form action="<?= $c->uri_for('/admin_console/document_create_form') ?>" method="post">
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
                    <label for="path">path</label>
                    <input size="40" type="text" name="path" value=""/>
                  </div>
                  <div>
                    <label for="class">Class</label>
                    <input type="text" size="20" name="_class" value="<?= $c->stash->{_class} ?>" id="document-class" />
                    <input type="button" value="変更" id="document-class-change-button" />
                  </div>
                  <div>
                    <label for="class">Content-Type</label>
                    <input type="text" size="20" name="content_type" value="text/plain"/>
                  </div>
                </fieldset>
                <?=r $c->render_string( $c->stash->{_class}->html_form_to_create ) ?>
                <div class="buttonrow">
                  <input type="submit" value="作成する" class="button"/>
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
    </div>
    <script type="text/javascript">
      $('#document-class-change-button').click( function() {
        var url = "<? $c->uri_for('/admin_console/document_create_form') | js ?>";
        url = url + "?_class=" + $('#document-class').val();
        location.href = url;
      });
    </script>
</body>
</html>
