? my ($c, $msg, $type) = @_;
? $type ||= "info";
            <div class="ui-widget flash-message">
              <div class="ui-state-highlight ui-corner-all" style="margin-top: 20px; padding: 0 .7em;">
                <p><span class="ui-icon ui-icon-<?= $type ?>" style="float: left; margin-right: .3em;"></span>
                <p><?= $msg ?></p>
              </div>
            </div>
