package Acore::CLI::SetupWAF;

use strict;
use warnings;
use Getopt::Long;
use Acore::CLI::SetupDB;
use Text::MicroTemplate qw/:all/;
use utf8;
use Encode qw/ encode_utf8 /;
use MIME::Base64;
use Path::Class qw/ file dir /;

our $AppName;
sub run {
    my $class = shift;
    my ($name, $help) = @_;
    $AppName = $name;

    if (!$name || $help) {
        usage();
        exit;
    }

    print "creating application $name\n";

    mkdir $name or die "Can't create dir $name: $!";
    chdir $name;

    for my $dir (qw/ static templates db script lib config t xt /,
                 "lib/$name", "lib/$name/Controller"
    ) {
        mkdir $dir
            or die "Can't create dir $name/$dir: $!";
        print "mkdir $name/$dir\n";
    }
    for my $file (qw/ script_server_pl script_index_cgi
                      script_fastcgi_pl
                      makefile_pl
                      lib_app_pm config_yaml
                      lib_app_modperl_pm
                      lib_app_controller_pm favicon_ico
                      anycms_logo
                      t_00_compile_t
                    /)
    {
        my ($filename, $tmpl, $raw, $permission) = __PACKAGE__->$file();
        my $fh = file($filename)->openw
            or die "Can't create file $filename: $!";
        if ($raw) {
            $fh->print($tmpl);
        }
        else {
            $fh->print( encode_utf8( render_mt($tmpl)->as_string ) );
        }
        $fh->close;
        print "create $name/$filename\n";
        chmod $permission, $filename if $permission;
    }
    my $dsn = sprintf "dbi:SQLite:dbname=db/%s.acore.sqlite", lc $AppName;
    Acore::CLI::SetupDB->run($dsn, "", "", "");
    chdir "..";
    1;
}

sub app_name { $AppName }

sub usage {
    print <<"    _END_OF_USAGE_";
 $0 --name=[AppName]

 options
   --help: show this usage.
    _END_OF_USAGE_

}

sub script_server_pl {
    return ("script/server.pl" => <<'    _END_OF_FILE_'
#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use HTTP::Engine;
use <?=r app_name() ?>;
use Getopt::Std;
use Acore::WAF::ConfigLoader;

my $opts = {};
getopts("p:c:", $opts);
$opts->{c} ||= "config/<?=r app_name() ?>.yaml";

my $config = Acore::WAF::ConfigLoader->new->load(
    $opts->{c}, $ENV{'<?=r uc app_name() ?>_CONFIG_LOCAL'},
);
my $engine = HTTP::Engine->new(
    interface => {
        module => 'ServerSimple',
        args   => {
            host => "0.0.0.0",
            port => $opts->{p} || 3000,
        },
        request_handler => sub {
            my $app = <?=r app_name() ?>->new;
            $app->handle_request($config, @_);
        },
    },
);
$engine->run;
    _END_OF_FILE_
    , undef, oct(755));
}

sub script_fastcgi_pl {
    return ("script/fastcgi.pl" => <<'    _END_OF_FILE_'
#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use HTTP::Engine;
use Acore::WAF::ConfigLoader;
use Acore::LoadModules;
use <?= app_name() ?>;
use utf8;

my $loader = Acore::WAF::ConfigLoader->new();
my $config = $loader->load(
    $ENV{'<?= uc app_name() ?>_CONFIG_FILE'},
    $ENV{'<?= uc app_name() ?>_CONFIG_LOCAL'},
);

HTTP::Engine->new(
    interface => {
        module => 'FCGI',
        args   => {
            keep_stderr => 1,
        },
        request_handler => sub {
            my $req = shift;
            $req = Acore::WAF::Util->adjust_request_fcgi($req);
            <?= app_name() ?>->new->handle_request($config, $req);
        },
    },
)->run;

__END__

=head1 lighttpd.conf

 fastcgi.server    = (
    "/<?= lc app_name() ?>.fcgi" => (
        "<?= lc app_name() ?>" => (
                "bin-path"     => "/path/to/<?= app_name() ?>/script/fastcgi.pl",
                "socket"       => "/tmp/<?= app_name ?>.socket",
                "check-local"  => "disable",
                "max-procs"    => 5,
                "idle-timeout" => 20,
                "bin-environment" => (
                    "<?= uc app_name() ?>_CONFIG_FILE" => "/path/to/App/config/<?= app_name() ?>.yaml",
                    "<?= uc app_name() ?>_CONFIG_LOCAL" => "/path/to/App/config/local.yaml"
                ),
                "bin-copy-environment" => (
                    "PATH", "SHELL", "USER"
                ),
                "broken-scriptfilename" => "enable"
        )
    )
)
    _END_OF_FILE_
    );
}

sub script_index_cgi {
    return ("script/index.cgi" => <<'    _END_OF_FILE_'
#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use HTTP::Engine::MinimalCGI;
use Acore::WAF::MinimalCGI;
use Acore::WAF::ConfigLoader;
use <?=r app_name() ?>;
use utf8;

my $loader = Acore::WAF::ConfigLoader->new({ cache_dir => "../db" });
my $config = $loader->load(
    $ENV{'<?=r uc app_name() ?>_CONFIG_FILE'} || "../config/<?=r app_name() ?>.yaml",
    $ENV{'<?=r uc app_name() ?>_CONFIG_LOCAL'},
);
$config->{root} = ".." if $config->{root} eq '.';

HTTP::Engine->new(
    interface => {
        module => 'MinimalCGI',
        request_handler => sub {
            my $app = <?=r app_name() ?>->new;
            $app->log->timestamp(0);
            $app->handle_request($config, @_);
        },
    },
)->run;
    _END_OF_FILE_
    , undef, oct(755));
}

sub lib_app_modperl_pm {
    return ("lib/${AppName}/ModPerl.pm" => <<'    _END_OF_FILE_'
package <?=r app_name() ?>::ModPerl;
use Any::Moose;
extends 'HTTP::Engine::Interface::ModPerl';
use HTTP::Engine;
use <?=r app_name() ?>;
use Acore::WAF::ConfigLoader;

my $loader = Acore::WAF::ConfigLoader->new();
my $config = $loader->load(
    $ENV{'<?=r uc app_name() ?>_CONFIG_FILE'},
    $ENV{'<?=r uc app_name() ?>_CONFIG_LOCAL'},
);

sub create_engine {
    my($class, $r, $context_key) = @_;
    HTTP::Engine->new(
        interface => {
            module          => 'ModPerl',
            request_handler => sub {
                my $req = shift;
                $req = Acore::WAF::Util->adjust_request_mod_perl($req);
                <?=r app_name() ?>->new->handle_request($config, $req);
            },
        },
    );
}
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 httpd.conf

  LoadModule env_module  modules/mod_env.so
  LoadModule perl_module modules/mod_perl.so
  
  PerlSwitches -Mlib=/path/to/<?=r app_name() ?>/lib
  PerlOptions +SetupEnv
  PerlModule Acore::LoadModules
  PerlModule <?=r app_name() ?>
  
  <VirtualHost 127.0.0.1:8080>
      <Location /<?=r lc app_name() ?>>
          PerlSetENV <?=r uc app_name() ?>_CONFIG_FILE  "/path/to/<?=r app_name() ?>/config/<?=r app_name() ?>.yaml"
          PerlSetENV <?=r uc app_name() ?>_CONFIG_LOCAL "/path/to/<?=r app_name() ?>/config/local.yaml"
          SetHandler modperl
          PerlResponseHandler <?=r app_name() ?>::ModPerl
      </Location>
  </VirtualHost>

    _END_OF_FILE_
    );
}

sub lib_app_controller_pm {
    return ("lib/${AppName}/Controller/Root.pm" => <<'    _END_OF_FILE_'
package <?=r app_name() ?>::Controller::Root;

use strict;
use warnings;
use utf8;

sub hello_world {
    my ($self, $c) = @_;
    $c->response->body( $c->welcome_message );
}

1;
    _END_OF_FILE_
    );
}

sub lib_app_pm {
    return ("lib/${AppName}.pm" => <<'    _END_OF_FILE_'
package <?=r app_name() ?>;

use strict;
use warnings;
use Any::Moose;
extends 'Acore::WAF';

my @plugins = qw/
    Session
    FormValidator
    FillInForm
/;
__PACKAGE__->setup(@plugins);

__PACKAGE__->meta->make_immutable;
no Any::Moose;

package <?=r app_name() ?>::Dispatcher;
use Acore::WAF::Util qw/ :dispatcher /;
use HTTPx::Dispatcher;

connect "", to controller "Root" => "hello_world";

connect "static/:filename", to class "<?=r app_name() ?>" => "dispatch_static";
connect "favicon.ico",      to class "<?=r app_name() ?>" => "dispatch_favicon" };

# Admin console
for (bundled "AdminConsole") {
    connect "admin_console/",                 to $_ => "index";
    connect "admin_console/static/:filename", to $_ => "static";
    connect "admin_console/:action",          to $_;
}

# Sites
connect "sites/",      to bundled "Sites" => "page";
connect "sites/:page", to bundled "Sites" => "page";

1;
    _END_OF_FILE_
    );
}

sub config_yaml {
    return ("config/${AppName}.yaml" => <<'    _END_OF_FILE_'
name: <?=r app_name() ?>
root: .
log:
  level: debug
debug: on
dsn:
  - dbi:SQLite:dbname=db/<?=r lc app_name() ?>.acore.sqlite
  -
  -
  - AutoCommit: 1
    RaiseError: 1
session:
  store:
    class: DBM
    args:
      file: db/<?=r lc app_name() ?>.session.dbm
      dbm_class: DB_File
  state:
    class: Cookie
    args:
      name: <?=r lc app_name() ?>_session_id

admin_console:
  disable_eval_functions:

    _END_OF_FILE_
    );
}

sub favicon_ico {
    no utf8;
    return ("static/favicon.ico", decode_base64(<<'    _END_OF_FILE_'
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQBAMAAADt3eJSAAAAElBMVEX/////////////C17hAGcA
AACr6v1WAAAAQUlEQVQImWMwhgIGY2NDQUFhCEPYUBiXCIwB1wVluEABguGk4uSi5OKkwqDiogIC
LlCGEkREyUUFokZFBagGpgsArcIY91nxh2cAAAAASUVORK5CYII=
    _END_OF_FILE_
    ), "raw");
}

sub makefile_pl {
    return ("Makefile.PL", <<'    _END_OF_FILE_'
use inc::Module::Install;
name '<?=r app_name() ?>';
build_requires 'Module::Install' => 0.77;
build_requires 'Test::More';
test_requires 'DBD::SQLite';
tests 't/*.t';
author_tests 'xt';
use_test_base;
auto_include;
WriteAll;
    _END_OF_FILE_
    );
}

sub t_00_compile_t {
    return ("t/00_compile.t", <<'    _END_OF_FILE_'
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok '<?= app_name() ?>';
}
    _END_OF_FILE_
    );
}

sub anycms_logo {
    no utf8;
    return ("static/anycms-logo.png", decode_base64(<<'    _END_OF_FILE_'
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
RU5ErkJggg==
    _END_OF_FILE_
    ), "raw");
}

1;
