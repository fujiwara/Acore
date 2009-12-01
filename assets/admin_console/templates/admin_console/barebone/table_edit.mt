? my $c = shift;
? my $columns_info = {};
? my $pkey      = $c->stash->{primary_key_info};
? my @pkey_cols = keys %{$pkey};

? for my $col (@{ $c->stash->{columns_info} }) {
?     $columns_info->{ $col->{COLUMN_NAME} } = $col;
? }
<div id="edit-form" title="edit">
  <form>
    <fieldset>
? my @cols = ();
? for my $col (@{ $c->stash->{columns_info} }) {
?     my $name = $col->{COLUMN_NAME};
?     push @cols, $name;
      <label for="element-<?= $name ?>"><?= $name ?></label>
?     if ($col->{TYPE_NAME} =~ /text/ || !$col->{COLUMN_SIZE}) {
        <textarea id="element-<?= $name ?>" rows="5" cols="40" class="textarea ui-widget-content ui-corner-all"></textarea>
?     } else {
        <input type="text" name="<?= $name ?>" id="element-<?= $name ?>" class="text ui-widget-content ui-corner-all" size="40" />
?     }
?     if ($col->{NULLABLE}) {
        <input class="null-check" type="checkbox" name="null-<?= $name ?>" id="null-<?= $name ?>" value="1"/><label for="null-<?= $name ?>">null</label>
?     }

      <br/>
? }
    </fieldset>
  </form>
</div>
? my $table = $c->stash->{table};

<script type="text/javascript">
  var cols      = [ <?= raw join(", ", map { qq{"$_"} } @cols) ?> ];
  var pkey_cols = [ <?= raw join(", ", map { qq{"$_"} } @pkey_cols) ?> ];
  var url       = '<?= $c->uri_for("@{[location]}/barebone/table_row/", $table) | js ?>';

  $("input.edit").click(
    function() {
      var ids      = $(this).attr("rel").split("---");
      var id_param = {};
      for ( var i = 0; i < pkey_cols.length; i++ ) {
        id_param[ pkey_cols[i] ] = ids[i];
      }
      $.getJSON( url, id_param, function(result) {
        for (var i = 0; i < cols.length; i++ ) {
          var val = result[ cols[i] ];
          if (val == null) {
            $("#null-" + cols[i]).attr("checked","checked");
            $("#element-" + cols[i]).val("").attr("disabled",true);
          }
          else {
            $("#null-" + cols[i]).attr("checked","");
            $("#element-" + cols[i]).val(val).attr("disabled",false);
          }
        }
        $("#edit-form").dialog("open");
      });
    });

  $("#edit-form").dialog({
    bgiframe: true,
    autoOpen: false,
    height: 400,
    width: 500,
    modal: false,
      buttons: {
        "update": function() {},
        "cancel": function() { $(this).dialog('close') },
        "delete": function() {}
      },
      close: function() {}
    });
</script>

