# -*- mode:perl -*-
use strict;
use Test::More;
qx{ rm -rf t/tmp/* t/tmp/.xslate };
ok "ok";

done_testing;
