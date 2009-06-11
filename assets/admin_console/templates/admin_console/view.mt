<?
   my $c = $_[0];
   $c->stash->{title} = "View の管理";
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
            <h2 class="icon"><div class="action_viewmag">View の管理</div></h2>
            <h3><a href="<?= $c->uri_for('/admin_console/view_create_form') ?>">新規作成</a></h3>
          </div>
          <div class="data">
            <table class="data">
              <tbody>
                <tr>
                  <th class="first" style="width: 20%;">id</th>
                  <th>views</th>
                </tr>
? for my $doc ( @{ $c->stash->{all_views} } ) {
                <tr>
                  <td><a href="<?= $c->uri_for('/admin_console/view_form', { id => $doc->{id} } ) ?>"><?= $doc->{id} ?></a></td>
                  <td>
                    <?= join(", ", sort keys %{ $doc->{views} } ) ?>
                  </td>
                </tr>
? }
              </tbody>
            </table>
          </div>
        </div>
        <div id="gamma">
          <div id="gamma-inner">
          </div>
        </div>
      </div>
    </div>
</body>
</html>
