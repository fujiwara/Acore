? my $c = shift;
          <div id="barebone-result">
            <a name="result" style="font-family: mono-space;">
              <?= $c->stash->{sql} ?>
            </a>
            <table class="data">
              <tbody>
                <tr>
                  <th class="first"></th>
? my @cols = $c->req->param('cols');
? for my $col (@cols) {
                  <th><?= $col ?></th>
? }
                  <th class="last"></th>
                </tr>
? while ( my $row = $c->stash->{result}->fetchrow_hashref ) {
                <tr>
                  <td></td>
?     for my $col (@cols) {
                  <td><?= Encode::decode_utf8( $row->{$col} ) ?></td>
?     }
                  <td></td>
                </tr>
? }
              </tbody>
            </table>
