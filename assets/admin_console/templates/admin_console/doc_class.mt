<?
  my $c = $_[0];
  $c->stash->{title} = "Document Class 作成";
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
            <h2 class="icon"><div class="mimetype_source">Document Class の作成</div></h2>
          </div>
          <div class="data">
            作成するクラス名 <input type="text" id="document-class" size="20" name="class" /><br/>
            <div id="name-error" style="color: #c33;">先頭が大文字から始まる 2文字以上の英数で入力してください</div>
            <? if ($c->form->has_error) { ?>
            <div id="exists-error" style="color: #c33;">すでにシステムに同じクラスが存在します</div>
            <? } ?>
            <ul id="downloads">
              <li><a id="download-pm">クラス定義ファイル(.pm) をダウンロード</a></li>
              <li><a id="download-tmpl">フォームテンプレート(.mt) をダウンロード</a></li>
            </ul>
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
          $('#downloads').show();
          $('#download-pm').attr({ href: "<?= $c->uri_for('/admin_console/doc_class_pm') | js ?>?class=" + name });
          $('#download-tmpl').attr({ href: "<?= $c->uri_for('/admin_console/doc_class_tmpl') | js ?>?class=" + name });
         }
         else {
           $('#name-error').show();
           $('#downloads').hide();
           $('#download-pm').removeAttr('href');
           $('#download-tmpl').removeAttr('href');
         }
      }
      $('#document-class').keyup( function() {
        $("#exists-error").hide();
        validate_name();
      });
      $('#downloads').hide();
      validate_name();
    </script>
</body>
</html>
