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
                    <input type="text" size="20" name="_class" value="Acore::Document"/>
                  </div>
                  <div>
                    <label for="class">Content-Type</label>
                    <input type="text" size="20" name="content_type" value="text/plain"/>
                  </div>
                </fieldset>
                <fieldset>
                  <legend>Content</legend>
                  <div>
                    <? if ($c->stash->{yaml_error_message}) { ?>
                    <p class="error">
                    <?=r $c->stash->{yaml_error_message} | html | html_line_break ?>
                    </p>
                    <? } ?>
                    <label for="content">YAML</label>
                    <textarea name="content" cols="60" rows="20"></textarea>
                  </div>
                </fieldset>
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
</body>
</html>
