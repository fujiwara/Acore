<?
  my $c = $_[0];
  $c->stash->{title} = "BareBone: テーブル: " . $c->stash->{table};
  $c->stash->{load_jquery_ui} = 1;
?>
? $c->log->info("location=" . location());
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
            <h2 class="icon"><div class="app_database">BareBone テーブル
                <a href="<?= $c->uri_for("/@{[location]}/barebone/table_list/all") ?>">一覧</a>
            </div></h2>
          </div>
          <h3><?= $c->stash->{table} ?></h3>
          <form action="<?= $c->uri_for("@{[location]}/barebone/table_select/", $c->stash->{table}, { _t => time() } ) ?>#result" method="get">
            <table class="data">
              <tbody>
                <tr>
                  <th class="first" style="width: 2em;">
                  </th>
                  <th style="width: 2em;">pkey</th>
                  <th style="width: 12em;">name</th>
                  <th style="width: 12em;">type</th>
                  <th style="width: 4em;">size</th>
                  <th>not null</th>
                  <th class="last">default</th>
                </tr>
? my $pkey = $c->stash->{primary_key_info};
? for my $col (@{ $c->stash->{columns_info} }) {
                <tr>
                  <td>
                    <input type="checkbox" name="cols" value="<?= $col->{COLUMN_NAME} ?>" checked="checked"/>
                  </td>
                  <td><?= $pkey->{ $col->{COLUMN_NAME} } ? "*" : "" ?></td>
                  <td><?= $col->{COLUMN_NAME} ?></td>
                  <td><?= $col->{TYPE_NAME} ?></td>
                  <td><?= $col->{COLUMN_SIZE} ?></td>
                  <td><?= $col->{NULLABLE} ? "" : "*" ?></td>
                  <td><?= $col->{COLUMN_DEF} ?></td>
                </tr>
? }
              </tbody>
            </table>
            <div>
<!--              DISTINCT <input type="checkbox" name="distinct" value="1"/>
              ON (<input type="text" name="distinct_on" value="" size="10"/>)<br/>
-->
              WHERE <input type="text" name="where" size="30"/>
              ORDER BY
              <select name="order_by">
                <option value=""></option>
? for my $col (@{ $c->stash->{columns_info} }) {
                <option value="<?= $col->{COLUMN_NAME} ?>"><?= $col->{COLUMN_NAME} ?></option>
? }
              </select>
              <select name="desc">
                <option value=""></option>
                <option value="1">DESC</option>
              </select>
              LIMIT <input type="text" name="limit" value="100" size="6"/>
              <br/>
              <input type="submit" value="select"/>
            </div>
          </form>

? if ($c->stash->{result}) {
?=    $c->render_part("@{[location]}/barebone/table_select.mt") | raw
? }
        </div>
        <div id="gamma">
          <div id="gamma-inner">
          </div>
        </div>
      </div>
    </div>
?= raw $c->render_part("@{[ location ]}/container_close.mt");
