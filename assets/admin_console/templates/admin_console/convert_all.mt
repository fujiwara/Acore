<?
   my $c = $_[0];
   $c->stash->{title}          = "Document の一括置換";
   $c->stash->{load_jquery_ui} = 1;
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
            <h2 class="icon"><div class="action_run">Document の一括置換</div></h2>
          </div>
          <div class="form-container">
            <form action="<?= $c->uri_for("/@{[ location ]}/convert_all") ?>" method="post" id="convert-form">
              <fieldset>
                <legend>置換処理</legend>
                <div>
                  <label for="path">Path (前方一致)</label>
                  <input type="text" id="path" name="path" size="20" value=""/>
                </div>
                <div>
                  <label for="code">Perl code</label>
                  <textarea id="code" name="code" rows="8" cols="60">
sub {
    my $doc = shift;

    # 置換処理をここに記述します

    return $doc;  # 書き換える場合
    # 書き換えない場合は return;
}
</textarea>
                </div>
              </fieldset>
              <div class="buttonrow">
                <input type="button" value="テスト" class="button" id="test-button"/>
                <input type="button" value="実行" class="button" id="submit-button"/>
                <input type="hidden" name="sid" value="<?= $c->session->session_id ?>"/>
              </div>
            </form>
          </div>
          <div class="data">
            <a name="result"/></a>
            <div id="test-result"></div>
          </div>
        </div>
      </div>
    </div>
    <div id="submit-dialog" title="確認">
      <span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>
      本当に処理を実行しますか?
    </div>
    <script type="text/javascript">
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
          '実行する': function() {
             $(this).dialog('close');
             $('#convert-form').submit();
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

      $('#test-button').click( function() {
        var url = "<?= $c->uri_for("/@{[ location ]}/convert_test") | js ?>";
        $('#test-result').html('<img src="<?= $c->uri_for("/@{[ location ]}/static/css/img/loading.gif") | js ?>"/>');
        $('#test-result').load(
          url, {
            code  : $('#code').val(),
            path  : $('#path').val(),
            sid   : "<?= $c->session->session_id | js ?>",
          },
          function () {
            location.href = '#result';
          }
        );
      });
    </script>
?= raw $c->render_part("@{[ location ]}/container_close.mt");

