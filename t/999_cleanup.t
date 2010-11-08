# -*- mode:perl -*-
use strict;
use Test::More;
qx{ rm -rf t/tmp/* t/db/.xslate_cache };
ok "ok";

done_testing;
