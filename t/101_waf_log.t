# -*- mode:perl -*-
use strict;
use Test::More tests => 26;

BEGIN {
    use_ok 'Acore::WAF::Log';
};

{
    my $log = Acore::WAF::Log->new;
    isa_ok $log => "Acore::WAF::Log";
    ok $log->can('level');
    is $log->level => 'info';

    ok $log->can('emerge');
    ok $log->can('alert');
    ok $log->can('critical');
    ok $log->can('error');
    ok $log->can('warning');
    ok $log->can('notice');
    ok $log->can('info');
    ok $log->can('debug');
    ok $log->can('caller');

    $log->level('error');
    is $log->level => "error";

    for my $l (qw/ emerge alert critical error / ) {
        ok $log->$l("$l message");
    }
    for my $l (qw/ warning notice info debug / ) {
        ok !$log->$l("$l message");
    }

    ok $log->flush;

    $log->caller(1);
    $log->error("error message"); my ($file, $line) = (__FILE__, __LINE__);
    like $log->buffer => qr{\Q at $file line $line\E};

    $log->flush;
    $log->caller(0);
    $log->timestamp(1);
    $log->error("error message");
    my $t = scalar localtime;
    like $log->buffer =>qr{^\[$t] \[error\] error message};

    $log->flush;
    $log->caller(0);
    $log->timestamp(0);
    $log->error("error message");
    like $log->buffer =>qr{^\[error\] error message};
}

