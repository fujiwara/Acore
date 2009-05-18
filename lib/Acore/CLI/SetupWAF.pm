package Acore::CLI::SetupWAF;

use strict;
use warnings;
use Getopt::Long;
use Acore::CLI::SetupDB;
use Text::MicroTemplate qw/:all/;
use utf8;
use Encode qw/ encode_utf8 /;
use MIME::Base64;

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

    for my $dir (qw/ static templates db script lib config /,
                 "lib/$name", "lib/$name/Controller"
    ) {
        mkdir $dir
            or die "Can't create dir $name/$dir: $!";
        print "mkdir $name/$dir\n";
    }
    for my $file (qw/ script_server_pl lib_app_pm config_yaml
                      lib_app_controller_pm
                      templates_hello_world_mt
                      favicon_ico /)
    {
        my ($filename, $tmpl, $raw) = __PACKAGE__->$file();
        open my $fh, ">", $filename,
            or die "Can't create file $filename: $!";
        if ($raw) {
            print $fh $tmpl;
        }
        else {
            print $fh encode_utf8( render_mt($tmpl)->as_string );
        }
        close $fh;
        print "create $name/$filename\n";
    }
    my $dsn = sprintf "dbi:SQLite:dbname=db/%s.acore.sqlite", lc $AppName;
    Acore::CLI::SetupDB->run($dsn, "", "", "");
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
use YAML ();

my $opts = {};
getopts("p:c:", $opts);
$opts->{c} ||= "config/<?=r app_name() ?>.yaml";

my $config = $opts->{c} ? YAML::LoadFile($opts->{c}) : {};
die "Can't load config." unless $config;

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
    );
}

sub lib_app_controller_pm {
    return ("lib/${AppName}/Controller/Root.pm" => <<'    _END_OF_FILE_'
package <?=r app_name() ?>::Controller::Root;

use strict;
use warnings;

sub hello_world {
    my ($self, $c) = @_;
    $c->render('hello_world.mt');
}

1;
    _END_OF_FILE_
    );
}

sub templates_hello_world_mt {
    return ("templates/hello_world.mt" => <<'    _END_OF_FILE_'
? my $c = $_[0];
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title><?= $c->config->{name} ?></title>
  </head>
  <body>
    <p>Hello World!</p>
  </body>
</html>
    _END_OF_FILE_
    , "raw");
}

sub lib_app_pm {
    return ("lib/${AppName}.pm" => <<'    _END_OF_FILE_'
package <?=r app_name() ?>;

use strict;
use warnings;
use Any::Moose;
extends 'Acore::WAF';

my @plugins = qw/ Session /;
__PACKAGE__->setup(@plugins);

__PACKAGE__->meta->make_immutable;
no Any::Moose;

package <?=r app_name() ?>::Dispatcher;
use HTTPx::Dispatcher;
connect "",
    { controller => "<?=r app_name() ?>::Controller::Root", action => "hello_world" };
connect "static/:filename",
    { controller => "<?=r app_name() ?>", action => "dispatch_static" };
connect "favicon.ico",
    { controller => "<?=r app_name() ?>", action => "dispatch_favicon" };

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

    _END_OF_FILE_
    );
}

sub favicon_ico {
    no utf8;
    return ("favicon.ico", decode_base64(<<'    _END_OF_FILE_'
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQBAMAAADt3eJSAAAAElBMVEX/////////////C17hAGcA
AACr6v1WAAAAQUlEQVQImWMwhgIGY2NDQUFhCEPYUBiXCIwB1wVluEABguGk4uSi5OKkwqDiogIC
LlCGEkREyUUFokZFBagGpgsArcIY91nxh2cAAAAASUVORK5CYII=
    _END_OF_FILE_
    ), "r");
}

1;
