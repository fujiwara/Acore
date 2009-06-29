? my $c = $_[0];
<div style="margin-left: 150px;">
  <h3>test result</h3>
  <table class="data" style="width: 90%;">
    <tbody>
      <tr>
        <th class="first" style="width: 30%;">id</th>
        <th class="last">doc</th>
      </tr>
? for my $doc (@{ $c->stash->{docs} }) {
      <tr>
        <td><?= ref $doc ? $doc->{_id} : $doc ?></td>
        <td>
          <? if (ref $doc) { ?>
          <pre><?= $doc | json("pretty") ?></pre>
          <? } else { ?>
          -
          <? } ?>
      </tr>
? }
    </tbody>
  </table>
</div>
