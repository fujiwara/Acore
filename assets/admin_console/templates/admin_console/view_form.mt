<?
   my $c = $_[0];
   require YAML;
   $c->stash->{title} = "View の管理";
   $c->stash->{load_jquery_ui} = 1;
   my $design       = $c->stash->{design};
   my $modify_alert = ( $design->{_id} =~ m{^_design/(?:tags|path)$} );
?>
?= raw $c->render_part("@{[ location ]}/header.mt");
?= raw $c->render_part("@{[ location ]}/container.mt");
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
                <a href="<?= $c->uri_for("/@{[ location ]}/view") ?>">View の管理</a></div></h2>
            <h3><a href="<?= $c->uri_for("/@{[ location ]}/view_create_form") ?>">新規作成</a></h3>
          </div>
?   if ( $c->flash->get('view_saved') ) {
?= raw     $c->render_part("@{[ location ]}/notice.mt", '保存されました');
?   }
          <div class="form-container">
? if ( $modify_alert ) {
            <div class="ui-widget">
              <div class="ui-state-highlight ui-corner-all" style="margin-top: 20px; padding: 0 .7em;"> 
                <p><span class="ui-icon ui-icon-info" style="float: left; margin-right: .3em;"></span>
                  <p>組み込みの view を変更、削除すると、管理コンソールのドキュメント管理が正常に利用できなくなる場合があります。</p>
              </div>
            </div>
? }

            <form action="<?= $c->uri_for("/@{[ location ]}/view_form") ?>" method="post" id="design-form">
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
                <legend><? if ($design->{_id}) { ?>
                  <?= $design->{_id} ?>
                  <input type="button" id="delete-button" value="削除する"/>
                  <? } ?></legend>
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
                <input type="button" value="更新する" class="button" id="submit-button"/>
                <input type="hidden" name="sid" value="<?= $c->session->session_id ?>"/>
              </div>
            </form>
          </div>
          <div class="data">
            <a name="result"/></a>
            <div id="test-result"></div>
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
      <? if ($modify_alert) { ?>
      組み込みの view を削除すると、管理コンソールのドキュメント管理が正常に利用できなくなります。
      <? } ?>
      本当に削除しますか?
    </div>
    <div id="submit-dialog" title="確認">
      <span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>
      大量のドキュメントがある場合、更新に時間がかかる可能性があります。更新しますか?
    </div>
    <script type="text/javascript">
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
             $('#design-form')
               .append('<input type="hidden" name="_method" value="DELETE" />')
               .submit();
          },
          Cancel: function() {
             $(this).dialog('close');
          }
        }
      });
      $('#delete-dialog').dialog('close');
      $('#delete-button').click( function() {
        $('#delete-dialog').dialog('open');
      })

      $('#submit-dialog').dialog({
        bgiframe: true,
        resizable: false,
        height:180,
        modal: true,
        overlay: {
          backgroundColor: '#000',
          opacity: 0.5
        },
        buttons: {
          '継続する': function() {
             $(this).dialog('close');
             $('#design-form').submit();
          },
          Cancel: function() {
             $(this).dialog('close');
          }
        }
      });
      $('#submit-dialog').dialog('close');
      $('#submit-button').click( function() {
        $('#submit-dialog').dialog('open');
      })

      $('.test-button').click( function() {
        var view = $(this).attr("rel").match('^test-for-(.+)$')[1];
        var url = "<?= $c->uri_for("/@{[ location ]}/view_test") | js ?>";
        $('#test-result').html('<img src="<?= $c->uri_for("/@{[ location ]}/static/css/img/loading.gif") | js ?>"/>');
        $('#test-result').load(
          url, {
            map   : $('#'+view+'-map').val(),
            reduce: $('#'+view+'-reduce').val(),
            sid   : "<?= $c->session->session_id | js ?>",
          },
          function () {
            location.href = '#result';
          }
        );
      });
    </script>
?= raw $c->render_part("@{[ location ]}/container_close.mt");

