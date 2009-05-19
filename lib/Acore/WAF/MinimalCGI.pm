package Acore::WAF::MinimalCGI;

use strict;
use warnings;
use URI;
{
    package HTTP::Engine::Request;
    sub uri  { $ENV{REQUEST_URI} }
    sub path { $ENV{PATH_INFO}   }
    sub base {
        my $base = $ENV{SCRIPT_URI};
        $base =~ m{/$} ? $base : $base . "/";
    }
}

1;

