? my $c = $_[0];
<div style="margin-left: 150px;">
  <h3>test result</h3>
  <table class="data" style="width: 90%;">
    <tbody>
      <tr>
        <th class="first" style="width: 30%;">key</th>
        <th class="last">value</th>
      </tr>
? for my $pair (@{ $c->stash->{pairs} }) {
      <tr>
        <td><?= $pair->[0] ?></td>
        <td><?= ref $pair->[1] ? ($pair->[1] | json) : $pair->[1] ?></td>
      </tr>
? }
    </tbody>
  </table>
</div>
