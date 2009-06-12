<?
   my $c = $_[0];
   $c->stash->{title} = "View の管理";
   require YAML;
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
            <h2 class="icon"><div class="action_viewmag">
                <a href="<?= $c->uri_for('/admin_console/view') ?>">View の管理</a></div></h2>
            <h3><a href="<?= $c->uri_for('/admin_console/view_create_form') ?>">新規作成</a></h3>
          </div>
          <div class="form-container">
? my $design = $c->stash->{design};
            <form action="<?= $c->uri_for('/admin_console/view_form') ?>" method="post">
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

?   if ($design->{_id}) {
              <input type="hidden" name="id" value="<?= $design->{_id} ?>"/>
?   } else {
              <input type="text" name="id" value="_design/" size="20"/>
?   }
              <fieldset>
                <legend><?= $c->req->param('id') ?></legend>
? for my $view ( sort keys %{ $design->{views} } ) {
                <div>
                  <label for="<?= $view ?>_name">Name</label>
                  <?= $view ?>
                  <input type="hidden" name="views" value="<?= $view ?>"/>
                  <input type="hidden" name="<?= $view ?>_name" value="<?= $view ?>" />
                </div>
                <div>
                  <label for="<?= $view ?>_map">Map</label>
                  <textarea id="<?= $view ?>-map" name="<?= $view ?>_map" rows="8" cols="60"><?= $design->{views}->{$view}->{map} ?></textarea>
                </div>
                <div>
                  <label for="<?= $view ?>_reduce">Reduce</label>
                  <textarea id="<?= $view ?>-reduce" name="<?= $view ?>_reduce" rows="8" cols="60"><?= $design->{views}->{$view}->{reduce} ?></textarea>
                </div>
                <div class="buttonrow">
                  <input type="button" value="test" class="test-button" rel="test-for-<?= $view ?>" />
                </div>
              </fieldset>
? }
              <div class="buttonrow">
                <input type="submit" value="更新する" class="button"/>
                <input type="hidden" name="sid" value="<?= $c->session->session_id ?>"/>
              </div>
            </form>
          </div>
          <div class="data">
            <div id="test-result"></div>
          </div>
        </div>
        <div id="gamma">
          <div id="gamma-inner">
          </div>
        </div>
      </div>
    </div>
    <script type="text/javascript">
      $('.test-button').click( function() {
        var view = $(this).attr("rel").match('^test-for-(.+)$')[1];
        var url = "<?= $c->uri_for('/admin_console/view_test') | js ?>";
        $('#test-result').load(
          url, {
            map   : $('#'+view+'-map').val(),
            reduce: $('#'+view+'-reduce').val(),
            sid   : "<?= $c->session->session_id | js ?>",
          },
          function () {}
        );
      });
    </script>
</body>
</html>
