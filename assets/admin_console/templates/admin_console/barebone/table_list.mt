<?
  my $c = $_[0];
  $c->stash->{title} = "BareBone: テーブル一覧";
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
            <h2 class="icon"><div class="app_kuser">BareBone テーブル一覧</div></h2>
          </div>
          <div class="data">
? for my $table ( @{ $c->stash->{tables} } ) {
            <dl class="tables">
              <dt class="data-operation"><a href="<?= $c->uri_for("/@{[ location ]}/barebone/table_info/", $table) ?>"><?= $table ?></a></dt>
              <dd>
                <p class="property">
                </p>
              </dd>
            </dl>
? }
          </div>
        </div>
        <div id="gamma">
          <div id="gamma-inner">
          </div>
        </div>
      </div>
    </div>
?= raw $c->render_part("@{[ location ]}/container_close.mt");
