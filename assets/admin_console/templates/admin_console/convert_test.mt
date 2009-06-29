? my $c = $_[0];
<div style="margin-left: 150px;">
  <h3>test result</h3>
  <table class="data" style="width: 90%;">
    <tbody>
      <tr>
        <th class="first">置換前</th>
        <th class="last">置換後</th>
      </tr>
? for my $pair (@{ $c->stash->{pair} }) {
      <tr>
        <td>
          <pre><?= $pair->[0] | json("pretty") ?></pre>
        </td>
        <td>
          <? if (defined $pair->[1]) { ?>
          <pre><?= $pair->[1] | json("pretty") ?></pre>
          <? } else { ?>-<? } ?>
        </td>
      </tr>
? }
    </tbody>
  </table>
</div>
