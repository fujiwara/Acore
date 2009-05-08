#!/usr/bin/perl
use strict;
use HTTP::Engine;
use Acore::SimpleApp;
use Getopt::Std;
use YAML ();
use Data::Dumper;

my $opts = {};
getopts("p:c:", $opts);

my $config = $opts->{c} ? YAML::LoadFile($opts->{c}) : {};
die "Can't load config." unless $config;

my $engine = HTTP::Engine->new(
    interface => {
        module => 'ServerSimple',
        args   => {
            host => "0.0.0.0",
            port => $opts->{p} || 4000,
        },
        request_handler => sub {
            my $app = Acore::SimpleApp->new;
            $app->handle_request($config, @_);
        },
    },
);
$engine->run;
