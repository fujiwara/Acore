<?
  my $c = $_[0];
  $c->stash->{title} = "ファイルエクスプローラー";
  $c->stash->{load_jquery_ui} = 1;
?>
?= raw $c->render_part("@{[ location ]}/header.mt");
?= raw $c->render_part("@{[ location ]}/container.mt");
    <div id="pagebody">
      <div id="pagebody-inner" class="clearfix">
        <div id="alpha">
          <div id="alpha-inner">
          <!-- /alpha -->
          </div>
        </div>
        <div id="beta">
          <div id="beta-inner" style="position: relative;">
            <h2 class="icon"><div class="action_view_tree">ファイルエクスプローラー</div></h2>
            <div id="explorer" style="position: relative; top: 0; left: 0; width: 250px; height: 400px; border: solid 1px #999; overflow: auto;"></div>
            <div id="file-editor" style="position: relative; left: 270px; top: -450px; width: 600px; display: none;">
              <h3 id="file-name"></h3>
              <div id="file-editor-main">
                <dl id="file-info">
                  <dt>サイズ</dt><dd class="size"></dd>
                  <dt>更新日時</dt><dd class="mtime"></dd>
                </dl>
                <div id="notice"></div>
                <a href="#" id="edit-file">ファイルを編集</a>
                <a href="#" id="download-file">ダウンロード</a>
                <br/>
                <div id="editor">
                  <textarea id="editor-text" style="width: 90%; height: 300px;"></textarea>
                  <br/>
                  <input type="button" id="save-file" value="保存"/>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div id="gamma">
          <div id="gamma-inner">
          </div>
        </div>
      </div>
    </div>

    <div id="save-dialog" title="確認">
      <span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>
      ファイルを上書きしますか?
    </div>
    <script src="<?= $c->uri_for("/@{[ location ]}/static/js/jqueryFileTree.js") ?>" type="text/javascript"></script>
    <script src="<?= $c->uri_for("/@{[ location ]}/static/js/jquery.easing.1.3.js") ?>" type="text/javascript"></script>
    <link href="<?= $c->uri_for("/@{[ location ]}/static/css/jqueryFileTree/jqueryFileTree.css") ?>" rel="stylesheet" type="text/css" media="screen" />
    <script type="text/javascript">
      $(document).ready( function() {

        $('#save-dialog').dialog({
          bgiframe: true,
          resizable: false,
          height:180,
          modal: true,
          overlay: {
            backgroundColor: '#000',
            opacity: 0.5
          },
          buttons: {
            '上書き': function() {
               $(this).dialog('close');
               save_file();
            },
            Cancel: function() {
               $(this).dialog('close');
            }
          }
        }).dialog('close');

        $('#explorer').fileTree({
          root: '/',
          script: '<?= $c->uri_for("@{[ location ]}/explorer_tree") | js ?>'
        }, function(file) {
          open_editor(file);
        });

        var file_info;

        var update_file_info = function (result) {
          if (typeof(result) == "string") {
            $('#notice').text("更新されました");
            result = eval( "(" + result + ")" );
          }
          file_info = result;
          $('#file-info .size').text( result.size + " bytes" );
          $('#file-info .mtime').text( result.mtime );
          if (result.size >=  1024*1024 || !result.editable) {
            $('#save-file').val("書き込み権限がありません").attr({disabled: true});
          }
          else {
            $('#save-file').val("保存").attr({disabled: false});
          }
          $('#editor').hide();
          $('#file-editor-main').show();
        }

        var open_editor = function (file) {
          $("#notice").text("");
          $("#file-editor").show();
          $('#file-editor-main').hide();
          file = file.replace(/^\.\//, '');
          $('#file-name').text(file);
          current_file = file;
          $.getJSON(
            '<?= $c->uri_for("@{[location]}/explorer_file_info") | js ?>',
            { "file": file, ".t": (new Date).getTime() },
            update_file_info
          );
          return false;
        }

        $('#download-file').click( function() {
          if (!file_info) { return };
          location.href = "<?= $c->uri_for("@{[ location ]}/explorer_download_file") | js ?>?file=" + encodeURIComponent(file_info.filename);
          return false;
        });

        $('#edit-file').click( function() {
          if (!file_info) { return };
          $("#notice").text("");
          $.getJSON(
            "<?= $c->uri_for("@{[ location ]}/explorer_file_info") | js ?>",
            { file: file_info.filename,
              body: 1,
              ".t": (new Date).getTime()
            },
            function (result) {
              $('#editor').show();
              $('#editor-text').val( result.body );
            }
          );
          return false;
        });

        $('#save-file').click( function() {
          $('#save-dialog').dialog("open");
        });

        var save_file = function() {
          $.post(
            "<?= $c->uri_for("@{[ location ]}/explorer_save_file") | js ?>",
            { file: file_info.filename,
              body: $("#editor-text").val(),
              sid : "<?= $c->session->session_id | js ?>"
            },
            update_file_info
          );
        }
      });
    </script>
?= raw $c->render_part("@{[ location ]}/container_close.mt");

