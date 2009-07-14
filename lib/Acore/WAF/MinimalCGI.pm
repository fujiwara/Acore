package Acore::WAF::MinimalCGI;

use strict;
use warnings;
use URI;
{
    package # hide from pause
        HTTP::Engine::Request;
    use HTTP::Engine::Request::Upload;

    $CGI::Simple::DISABLE_UPLOADS = 0;
    $CGI::Simple::POST_MAX        = 1024 * 1024 * 10;

    sub uri  { $ENV{PATH_INFO} }
    sub path { $ENV{PATH_INFO} }
    sub base {
        my $self = shift;
        $self->{base} ||= URI->new(
            sprintf(
                "http%s://%s%s/",
                ($ENV{HTTPS} ? "s" : ""),
                ($ENV{HTTP_HOST} || $ENV{SERVER_NAME}),
                ($ENV{SCRIPT_NAME})
            )
        );
        $self->{base};
    }
    sub address { $ENV{REMOTE_ADDR} }

    no warnings 'redefine';
    sub method { $ENV{REQUEST_METHOD} || 'GET' }

    sub uploads {
        my $self = shift;
        $self->{uploads} ||= $self->_prepare_uploads;
    }

    sub upload {
        my $self = shift;
        return keys %{ $self->uploads } if @_ == 0;

        if (@_ == 1) {
            my $upload = shift;
            return wantarray ? () : undef unless exists $self->uploads->{$upload};
            if (ref $self->uploads->{$upload} eq 'ARRAY') {
                return (wantarray)
                    ? @{ $self->uploads->{$upload} }
                    : $self->uploads->{$upload}->[0];
            } else {
                return (wantarray)
                    ? ( $self->uploads->{$upload} )
                    : $self->uploads->{$upload};
            }
        }
    }

    sub _prepare_uploads {
        my $self = shift;

        $self->{cs} ||= CGI::Simple->new();
        my $q = $self->{cs};

        my %uploads;
        for my $name ( keys %{ $q->{".upload_fields"} } ) {
            my $filename = $q->{".upload_fields"}->{$name};
            my @uploads;
            my $headers = HTTP::Headers::Fast->new();
            push(
                @uploads,
                HTTP::Engine::Request::Upload->new(
                    headers  => $headers,
                    fh       => $q->upload($filename),
                    size     => $q->upload_info($filename, 'size'),
                    filename => $filename,
                )
            );
            $uploads{$name} = @uploads > 1 ? \@uploads : $uploads[0];
        }
        return \%uploads;
    }
}

{
    package # hide from pause
        HTTP::Engine::Request::Upload;
    no warnings "redefine";
    sub copy_to {
        my $self = shift;
        require File::Copy;
        File::Copy::copy( $self->fh, @_ );
    }
}

1;

