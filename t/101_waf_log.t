# -*- mode:perl -*-
use strict;
use Test::More;
use Test::Output;
use Path::Class qw/ file /;

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
    ok $log->can("color");

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

    $log->caller(2);
    sub call {
        $log->error("error message");
    }
    call(); ($file, $line) = (__FILE__, __LINE__);
    like $log->buffer => qr{\Q at $file line $line\E};
    $log->flush;

    $log->caller(0);
    $log->timestamp(1);
    $log->error("error message");
    my $t = scalar localtime;
    like $log->buffer => qr{\[$t] \[error\] error message};

    $log->flush;
    $log->caller(0);
    $log->timestamp(0);
    $log->error("error message");
    like $log->buffer => qr{\[error\] error message};

    $log->disabled(1);
    is $log->disabled => 1;
    $log->error('ERROR');
    is $log->flush => undef;
}

{
    my $log = Acore::WAF::Log->new({ file => "t/tmp/error_log" });
    is $log->file => "t/tmp/error_log";
    $log->error('put to file');
    $log->flush;

    like file("t/tmp/error_log")->slurp => qr/put to file/;

    $log->file(undef);
    $log->error('put to stderr');
    $log->flush;

    $log->file("t/tmp/error_log");
    $log->error('put to file more');
    $log->flush;
    like file("t/tmp/error_log")->slurp => qr/put to file more/;
}


{
    my $log = Acore::WAF::Log->new();
    $log->error("%s %d", "string", 123);
    like $log->buffer => qr{string 123};

    $log->error("float %.2f", 0.123456);
    like $log->buffer => qr{float 0\.12};

    $log->error('%percent');
    like $log->buffer => qr{\%percent};
}


{
    my $log = Acore::WAF::Log->new();
    ok $log->configure({
        level     => "debug",
        file      => "tmp/foo.log",
        timestamp => 0,
        caller    => 1,
    });
    is $log->level     => "debug";
    is $log->file      => "tmp/foo.log";
    is $log->timestamp => 0;
    is $log->caller    => 1;
}

for my $color ( 0, 1 ) {
    my $log = Acore::WAF::Log->new();
    $log->level("debug");
    $log->color($color);
    for my $l (qw/ emerge alert critical error warning notice info debug /) {
        $log->$l("$l message.");
    }
    $log->flush;
}

{
    stderr_like sub {
        do {
            my $log = Acore::WAF::Log->new;
            $log->error("error message");
        };
    }, qr{error message}, "flash on DESTROY";
}


done_testing;
