package t::WAFTest::Engine;

use strict;
use warnings;
use Exporter 'import';
use HTTP::Request;
use HTTP::Response;

our @EXPORT = qw/ create_engine
                  create_request
                  res_from_psgi
                  res_to_psgi
                  run_engine_test
                  convert_charset
                /;

sub res_from_psgi {
    my $res = HTTP::Message::PSGI::res_from_psgi($_[0]);
    $res->header( status => $res->code );
    $res->header( "Content-Length" => length($res->content) )
        if $res->code != 304;
    $res;
}

sub req_to_psgi {
    HTTP::Message::PSGI::req_to_psgi(@_);
}

sub new {
    my $class = shift;
    my %args  = @_;
    bless \%args, $class;
}

sub run {
    require Plack::Request;
    require HTTP::Message::PSGI;

    my $self      = shift;
    my $http_req  = shift;
    my $plack_req = Plack::Request->new( $http_req->to_psgi );
    my $plack_res = $self->{interface}->{request_handler}->($plack_req);
    res_from_psgi( $plack_res->finalize );
}

sub create_engine {
    my $engine = $ENV{TEST_PSGI} ? "t::WAFTest::Engine" : "HTTP::Engine";
    $engine->require;
    $engine;
}

sub create_request {
    my %args = @_;
    if ( $ENV{TEST_PSGI} ) {
        Test::More::diag("Testing PSGI request");
        require HTTP::Message::PSGI;
        require Plack::Request;
        my $method = delete $args{method};
        my $uri    = delete $args{uri};
        my $body   = delete $args{body};
        my $req = HTTP::Request->new(
            $method => $uri,
            undef,
            $body,
        );
        for my $name ( keys %args ) {
            $req->header( $name => $args{$name} );
        }
        Plack::Request->new( $req->to_psgi );
    }
    else {
        Test::More::diag("Testing HTTP::Engine request");
        HTTP::Engine::Test::Request->new(%args);
    }
}


sub run_engine_test {
    my ($config, $block, $ctx, $app_class) = @_;
    $ctx       ||= {};
    $app_class ||= "t::WAFTest";
    chomp $app_class;
    $app_class->require;

    sleep( $block->wait || 0 );

    my $method = $block->method || "GET";
    my $req = HTTP::Request->new( $method => $block->uri );
    $req->protocol('HTTP/1.0');
    $req->content( $block->body ) if $block->body;
    $req->header(
        "Content-Length" => $block->body ? length($block->body) : 0,
        "Content-Type"   => "text/plain",
    );
    for my $header_line ( split /\n/, ($block->request || "") ) {
        my ($name, $value) = split /: /, $header_line, 2;
        $req->header($name => $value);
    }
    $req->header(
        "Cookie" => "http_session_sid=$ctx->{SessionId}"
    ) if $ctx->{SessionId};

    my @res_args = $block->preprocess ? eval $block->preprocess : ();
    die $@ if $@;

    my $engine = create_engine->new(
        interface => {
            module => 'Test',
            request_handler => sub {
                my $app = $app_class->new;
                $app->handle_request($config, @_);
            },
        },
    );
    my $response = $engine->run($req);

    if ($block->handle_response) {
        package main;
        eval $block->handle_response;
        die $@ if $@;
    }
    else {
        my $data = $response->headers->as_string."\n".$response->content;
        $data =~ s/[\r\n]+\z//;
        $data = handle_session($ctx, $data);
        Test::More::is $data => $block->raw ? $block->response
                                            : sprintf($block->response, @res_args),
                       $block->name;
    }
    eval $block->postprocess if $block->postprocess;
    die $@ if $@;
}

sub convert_charset {
    my $str = shift;
    if ( $str =~ /Shift_JIS/i ) {
        Encode::from_to($str, 'utf-8', 'cp932');
    }
    $str;
}

sub handle_session {
    my $ctx = shift;
    my $str = shift;
    $str =~ s{Set-Cookie: http_session_sid=(.+?);}
             {Set-Cookie: http_session_sid=SESSIONID;};
    $ctx->{SessionId} = $1;
    $str;
}

1;

