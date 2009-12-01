? my $c = shift;
? my $pkey = $c->stash->{primary_key_info};
? my @pkey_cols = keys %{$pkey};
? my $editable  = @pkey_cols;
          <div id="barebone-result">
            <a name="result" style="font-family: mono-space;">
              <?= $c->stash->{sql} ?>
            </a>
? unless ($editable) {
           <p>primary key が定義されていないテーブルは編集できません</p>
? }
            <table class="data">
              <tbody>
                <tr>
                  <th class="first">編集</th>
? my @cols = $c->req->param('cols');
? for my $col (@cols) {
                  <th><?= $col ?></th>
? }
                  <th class="last"></th>
                </tr>
? while ( my $row = $c->stash->{result}->fetchrow_hashref ) {
                <tr>
                  <td>
?     if (@pkey_cols) {
                     <input value="e" type="button" class="edit" rel="<?= join('---', map { $row->{$_} } @pkey_cols ) ?>"/>
?     }
                  </td>
?     for my $col (@cols) {
                  <td><?= Encode::decode_utf8( $row->{$col} ) ?></td>
?     }
                  <td></td>
                </tr>
? }
              </tbody>
            </table>
? if ($editable) {
?=   $c->render_part("@{[location]}/barebone/table_edit.mt") | raw
? }
