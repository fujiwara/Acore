<?
  my $c = $_[0];
  $c->stash->{title} = "Document Class 作成";
  $c->stash->{load_jquery_ui} = 1;
?>
?=r $c->render_part("@{[ location ]}/header.mt");
?=r $c->render_part("@{[ location ]}/container.mt");
    <div id="pagebody">
      <div id="pagebody-inner" class="clearfix">
        <div id="alpha">
          <div id="alpha-inner">
          </div>
          <!-- /alpha -->
        </div>
        <div id="beta">
          <div id="beta-inner">
            <h2 class="icon"><div class="mimetype_source">Document Class の作成</div></h2>
          </div>
          <div class="data">
            <form action="<?= $c->uri_for("/@{[ location ]}/doc_class") ?>" method="post">
              <input type="hidden" name="sid" value="<?= $c->session->session_id ?>"/>
              <h3>作成するクラス名</h3>
              <input type="text" id="document-class" size="20" name="class" /><br/>
              <div id="name-error" style="color: #c33;">先頭が大文字から始まる 2文字以上の英数で入力してください</div>
              
              <div id="form-generator">
                <h3>フォーム要素</h3>
                <div id="create-form">
                  ラベル <input type="text" id="element-label" value="" size="20"/>
                  要素名 (xpath)<input type="text" id="element-name" value="/" size="20"/>
                  <select id="element-type">
                    <option value="text">テキストボックス</option>
                    <option value="textarea">テキストエリア</option>
                    <option value="radio">ラジオボタン</option>
                    <option value="checkbox">チェックボックス</option>
                    <option value="select">セレクトボックス</option>
                  </select>
                  <input type="button" id="element-add-button" value="追加"/>
                </div>
                <h3></h3>
                <div class="form-container">
                  <fieldset>
                    <legend>生成されたフォーム</legend>
                    <div id="form-elements"></div>
                  </fieldset>
                </div>
                <h3>HTML</h3>
                <textarea id="form-html" name="form-html" rows="15" cols="60"></textarea>
                <ul id="downloads">
                  <li><input type="submit" name="download-pm" value="クラス定義ファイル(.pm) をダウンロード"/></li>
                  <li><input type="submit" name="download-tmpl" value="フォームテンプレート(.mt) をダウンロード"/></li>
                </ul>
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
      var validate_name = function() {
        var name = $('#document-class').val();
        if (name.match(/^[A-Z]([_a-zA-Z0-9]+|::)*[_a-zA-Z0-9]+$/)) {
          name = encodeURIComponent(name);
          $('#name-error').hide();
          $('#form-generator').show();
        }
        else {
          $('#name-error').show();
          $('#form-generator').hide();
        }
      }
      $('#document-class').keyup( function() {
        $("#exists-error").hide();
        validate_name();
      });
      $('#form-generator').hide();
      validate_name();

      $('#element-add-button').click( function() {
        var name = $('#element-name').val();
        var html = '';
        if (name == '/' || !name.match(/^\//)) { return }

        switch ($('#element-type').val()) {
          case "text":
            html = "<input type='text' name='_NAME_' size='20'/>"; break;
          case "textarea":
            html = "<textarea name='_NAME_' rows='3' cols='20'></textarea>"; break;
          case "checkbox":
            html = "<input type='checkbox' name='_NAME_' value=''/>"; break;
          case "radio"   :
            html = "<input type='radio' name='_NAME_' value=''/>"; break;
          case "select"  :
            html = "<select name='_NAME_'>\n    <option value=''></option>\n  </select>"; break;
          default : break;
        }
        html = "<div>\n  <label for='_NAME_'>" + $('#element-label').val() + "</label>\n  " + html + "\n</div>\n";
        html = html.replace(/_NAME_/g, name );
        $('#form-elements').append(html);

        $('#form-html').val( $('#form-elements').html() );
      })
      $('#form-html').change( function() {
        $('#form-elements').html( $('#form-html').val() );
      });

    </script>
?=r $c->render_part("@{[ location ]}/container_close.mt");

