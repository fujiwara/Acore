? my $c = $_[0];
<style type="text/css">
  table.view-result td {
    padding: 0.5em;
    margin: 0.5em;
  }
  table.view-result th {
    padding: 0.5em;
    margin: 0.5em;
  }
</style>
<table border="1" class="view-result">
  <tr>
    <th>key</th><th>value</th>
  </tr>
? for my $pair (@{ $c->stash->{pairs} }) {
  <tr>
    <td><?= $pair->[0] ?></td>
    <td><?= $pair->[1] ?></td>
  </tr>
? }
</table>
