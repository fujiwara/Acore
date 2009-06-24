? my $c = $_[0];
            <form action="<?= $c->uri_for('/admin_console/document_list') ?>" method="get" id="document-search-form">
              <select name="type" id="type-selector">
                <option value=""></option>
? for my $design ( $c->acore->storage->document->all_designs ) {
?     (my $name = $design->{id}) =~ s{^_design/}{};
                <option value="<?= $name ?>"><?= $name ?></option>
? }
              </select> で <input type="text" name="q" size="20" /> を
              <span id="selector-notice"></span>
              <input type="submit" value="表示" />
              <input type="text" name="limit" size="4" value="<?= $c->stash->{limit} ?>"/>docs/page
              <input type="checkbox" name="download" value="1" id="download" /><label for="download">Download</label>
              <br/>
              表示する属性
              <span id="add-document-keys">
? my $keys = $c->session->get('document_show_keys') || [];
? for my $key ( @$keys ) {
                <input type="text" name="keys" size="10" value="<?= $key ?>" alt="<?= $key ?>"/>
? }
              </span>
              <input type="button" id="add-document-key" value="追加"/>
              <input type="submit" value="更新" id="add-keys-submit" name="update_keys"/>
            </form>
            <script type="text/javascript">
              var type_changed = function() {
                var type = $('#type-selector').val();
                if (type === 'path') {
                  $('#selector-notice').html('前方一致');
                }
                else if (type === 'tags') {
                  $('#selector-notice').html('完全一致');
                }
                else {
                  $('#selector-notice').html('<select name="match"><option value="start_with">前方一致</option><option value="full">完全一致</option></select>');
                }
              }
              type_changed();
              $('#type-selector').change(type_changed);

              $('#add-document-key').click( function() {
                $('#add-document-keys').append("<input type='text' name='keys' size='10' />");
              });

            </script>
