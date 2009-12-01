<?
   my $c = $_[0];
   my $doc = $c->stash->{document};
   $c->stash->{title} = "Document の編集 - " . ($doc && $doc->{title} or "" );
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
            <div class="data">

              <h2 class="icon"><div class="mimetype_kmultiple"><a href="<?= $c->uri_for("/@{[ location ]}/document_list") ?>">Document の管理</a></div></h2>

?= raw $c->render_part("@{[ location ]}/document_serach_form.mt");

            </div>
?        if ( $c->flash->get('document_saved') ) {
?= raw          $c->render_part("@{[ location ]}/notice.mt", '保存されました');
?        } elsif ( $c->flash->get('attachment_added') ) {
?= raw          $c->render_part("@{[ location ]}/notice.mt", '添付ファイルを保存しました');
?        } elsif ( $c->flash->get('attachment_deleted') ) {
?= raw          $c->render_part("@{[ location ]}/notice.mt", '添付ファイルを削除しました');
?        }
?        if ( $c->flash->get('document_sent') ) {
?= raw          $c->render_part("@{[ location ]}/notice.mt", '正常に送信されました');
?        } elsif ( my $msg = $c->flash->get('document_sent_error') ) {
?= raw          $c->render_part("@{[ location ]}/notice.mt", '送信に失敗しました.' . $msg );
?        }
            <div class="form-container">

? if (!$doc) {
              <p class="error">id = <?= $c->req->param('id') ?> の Document は存在しません</p>
? } else {
              <form action="<?= $c->uri_for("/@{[ location ]}/document_form") ?>" method="post" id="document-form" enctype="multipart/form-data">
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
?               if ( $doc->can('attachment_files') ) {
                  <div>
                    <label for="attachment-files">添付ファイル</label>
                    <input type="file" id="attachment-file" name="attachment_file" size="30"/>
                    <input type="button" id="add-attachment" value="upload"/>
                    <img src="<?= $c->uri_for("/@{[ location ]}/static/images/uploading.gif") ?>" alt="uploading..." style="display: none;" id="uploading-icon"/>
                    <input type="hidden" name="n" id="attachment-number" value=""/>
                    <ul style="margin-left: 200px; list-style-image: url(<?= $c->uri_for("/@{[ location ]}/static/css/icon/16/mimetype_misc.png") ?>);">
<?                  my $n = 0;
                    for my $file (@{ $doc->attachment_files }) {
?>
                      <li><a href="<?= $c->uri_for("/@{[ location ]}/document_attachment", { id => $doc->id, n => $n }) ?>"><?= $file->basename | uri_unescape ?></a>
                        <a rel="<?= $n ?>" class="delete-attachment-button">[×]</a>
                      </li>
<?                      $n++; } ?>
                    </ul>
?               }

                </fieldset>

                <?= raw $c->render_string( $doc->html_form_to_update, $doc ) | fillform($doc) ?>
                <fieldset>
                  <legend id="show-document-yaml">Raw</legend>
                  <div>
? require YAML;
                    <pre id="document-yaml"><?= YAML::Dump($doc->to_object) ?></pre>
                  </div>
                </fieldset>

                <div class="buttonrow">
                  <input type="submit" value="更新する" class="button"/>
                  <input type="hidden" name="sid" value="<?= $c->session->session_id ?>"/>
                  <br/>
         <? if ( my $send_to = $c->config->{admin_console}->{send_to}) { ?>
                  <input type="checkbox" id="send-to-checkbox" name=".send" value="1"/>
                  <?= $send_to->{name} | utf8 ?> に対して Document を送信する
         <? } ?>
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
    <div id="delete-dialog" title="確認">
      <span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>
      本当に削除しますか?
    </div>
    <div id="delete-attachment-dialog" title="確認">
      <span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>
      添付ファイルを削除しますか?
    </div>

    <script type="text/javascript">
    $(document).ready( function(){
      $('#delete-dialog').dialog({
        bgiframe: true,
        resizable: false,
        height:140,
        modal: true,
        overlay: {
          backgroundColor: '#000',
          opacity: 0.5
        },
        buttons: {
          '削除する': function() {
            $('#document-form').attr({'action' : '<?= $c->uri_for("/@{[ location ]}/document") | js ?>'});
            $('#document-form').append('<input type="hidden" name="_method" value="DELETE"/>');
            $(this).dialog('close');
            $('#document-form').submit();
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
      $('#document-yaml').hide();
      $('#show-document-yaml').click( function() {
         $('#document-yaml').toggle();
      }).css({ cursor: "pointer" })


      $('#add-attachment').click( function() {
        if ( $('#attachment-file').val() ) {
          var f = $('#document-form');
          $(this).hide();
          $('#uploading-icon').show();
          f.attr('action', '<?= $c->uri_for("/@{[ location ]}/document_attachment") | js ?>').submit();
        }
        else {
          return false;
        }
      });

      $('#delete-attachment-dialog').dialog({
        bgiframe: true,
        resizable: false,
        height:140,
        modal: true,
        overlay: {
          backgroundColor: '#000',
          opacity: 0.5
        },
        buttons: {
          '削除する': function() {
            $('#document-form').attr({'action' : '<?= $c->uri_for("/@{[ location ]}/document_attachment") | js ?>'});
            $('#document-form').append('<input type="hidden" name="_method" value="DELETE"/>');
            $(this).dialog('close');
            $('#document-form').submit();
          },
          Cancel: function() {
             $(this).dialog('close');
          }
        }
      });
      $('#delete-attachment-dialog').dialog('close');

      $('a.delete-attachment-button')
        .css({ cursor: "pointer" })
        .click( function() {
           var n = $(this).attr('rel');
           $('#attachment-number').val(n);
           $('#delete-attachment-dialog').dialog('open');
        });
    });

    <?= raw $c->render_part("@{[ location ]}/flash_message.js") ?>
    </script>
?= raw $c->render_part("@{[ location ]}/container_close.mt");

