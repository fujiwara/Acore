# -*- mode:perl -*-
use strict;
use Test::More;
qx{ rm -rf t/tmp/* t/tmp/.xslate_cache };
ok "ok";

done_testing;
