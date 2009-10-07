<?
  my $c = $_[0];
  $c->stash->{title} = "ユーザの管理";
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
            <h2 class="icon"><div class="app_kuser">ユーザの管理</div></h2>
          </div>
          <h3><a href="<?= $c->uri_for("/@{[ location ]}/user_create_form") ?>">新規作成</a></h3>
          <h3><a href="#" id="toggle-upload-form">一括登録</a></h3>
          <div class="form-container">
            <form action="<?= $c->uri_for("/@{[ location ]}/user_upload") ?>" method="post" enctype="multipart/form-data" id="upload-form">
              <input type="hidden" name="sid" value="<?= $c->session->session_id ?>"/>
              CSV <input type="file" name="upload_file" size="20"/>
              <input type="submit" value="アップロード" id="upload-submit-button"/>
              <img src="<?= $c->uri_for("/@{[ location ]}/static/images/uploading.gif") ?>" alt="uploading..." id="uploading-icon" style="display: none;"/>
              <a href="#" id="help-for-csv">ファイル形式のヘルプ</a>
            </form>
          </div>
          <div class="data">
            <h3>
              すべてのユーザ
              <a href="<?= $c->uri_for("/@{[ location ]}/user_download") ?>">CSVダウンロード</a>
            </h3>
            <p>絞り込み: <input type="text" id="search-users" size="30" />
              <input type="button" id="clear-search-button" value="クリア"/>
            </p>
? for my $user ( @{ $c->stash->{all_users} } ) {
            <dl class="users" rel="<?= $user->name ?> <?= CORE::join(" ", $user->roles) ?> <?= CORE::join(" ", map { $user->attr($_) } $user->attributes ) ?>">
              <dt class="data-operation"><a href="<?= $c->uri_for("/@{[ location ]}/user_form", { name => $user->name } ) ?>"><?= $user->name ?></a></dt>
              <dd>
                <p class="property">
                  <span class="key">Roles:</span><span class="val"><?= CORE::join(", ", $user->roles) ?></span>
                  <? for my $attr ( $user->attributes ) { ?>
                    <span class="key"><?= $attr ?>:</span>
                    <span class="val"><?= $user->attr($attr) ?></span>
                  <? } ?>
                </p>
              </dd>
            </dl>
? }
          </div>
        </div>
        <div id="gamma">
          <div id="gamma-inner">
          </div>
        </div>
      </div>
    </div>
    <div id="help-for-csv-dialog">
      <p>
        CSV ファイルは以下の形式に従って作成してください
        <ul>
          <li>文字コード UTF-8</li>
          <li>改行コード LF または CR + LF</li>
          <li>1行目はヘッダ行</li>
          <li>ヘッダ行には name カラムが必須</li>
          <li>password カラムが存在すれば、そのパスワードに更新</li>
          <li>それ以外のヘッダ行は追加属性として登録</li>
        </ul>
      </p>
    </div>
    <script type="text/javascript">
    $(document).ready( function() {

      $('#upload-form').hide().submit( function() {
         $('#upload-submit-button').hide();
         $('#uploading-icon').show();
      });

      $('#toggle-upload-form').click( function() {
         $('#upload-form').toggle();
         return false;
      });


      $('#help-for-csv-dialog').hide()
      $('#help-for-csv').click( function() {
        $('#help-for-csv-dialog').show().dialog({ width: 400 });
        return false;
      });

      var users_dl = $('dl.users');
      $('#search-users').keyup( function() {
        var text_org = $('#search-users').val();
        var text_arr = text_org.replace(/　/g, " ").replace(/\s+/g, " ").replace(/([+.*^$!?(){}|\[\]\\])/g, "\\$1").split(/ +/);

        users_dl.show();

        for ( var i = 0; i < text_arr.length; i++ ) {
          if (text_arr[i] == "") continue;
          var regex = new RegExp(text_arr[i], "i");
          users_dl.each( function() {
            if (!$(this).attr('rel').match(regex)) {
              $(this).hide();
            }
          });
        }
      });
      
      $('#clear-search-button').click( function() {
        $('#search-users').val("");
        users_dl.show();
      })

    });
    </script>
?= raw $c->render_part("@{[ location ]}/container_close.mt");

