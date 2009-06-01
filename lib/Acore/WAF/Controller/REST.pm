package Acore::WAF::Controller::REST;
use strict;
use warnings;
use JSON;

sub get_document {
    my ($self, $c, $args) = @_;
    my $doc
        = defined $args->{id}
            ? $c->acore->get_document({ id => $args->{id} })
        : defined $args->{path}
            ? $c->acore->get_document({ path => "/" . $args->{path} })
        : undef;
    $c->error( 404 => "Document not found." )
        unless $doc;
    $doc;
}

sub document_GET {
    my ($self, $c, $args) = @_;
    my $doc = $c->forward( $self => "get_document", $args );

    my $object = $doc->to_object;
    $object->{id} = delete $object->{_id};

    $c->res->body( JSON->new->encode($object) );
    $c->res->content_type('application/json; charset=utf-8');
}

sub document_PUT {
    my ($self, $c, $args) = @_;
    my $doc = $c->forward( $self => "get_document", $args );

    my $body = $c->request->raw_body;
    utf8::decode($body) unless utf8::is_utf8($body);

    my $json   = JSON->new;
    my $object = eval { $json->decode($body) };
    if ( $@ || !$object || ref $object ne "HASH" ) {
        $c->error( 400 => "Can't decode json. $@" );
    }
    for my $key (keys %$object) {
        next if $key =~ /\A(?:id|created_on|updated_on|_class)\z/;
        $doc->{$key} = $object->{$key};
    }
    $c->acore->put_document($doc);
    $c->res->body("OK");
}

sub document_DELETE {
    my ($self, $c, $args) = @_;
    my $doc = $c->forward( $self => "get_document", $args );
    $c->acore->delete_document($doc);
    $c->res->body("OK");
}

sub new_document_POST {
    my ($self, $c, $args) = @_;
    my $body = $c->request->raw_body;
    utf8::decode($body) unless utf8::is_utf8($body);

    my $json   = JSON->new;
    my $object = eval { $json->decode($body) };
    if ( $@ || !$object || ref $object ne "HASH" ) {
        $c->error( 400 => "Can't decode json. $@" );
    }
    my $doc_class = $object->{_class} || "Acore::Document";
    my $doc = $c->acore->put_document( $doc_class->new($object) );
    my $uri = $c->rel_uri_for( "document/id/", $doc->id );
    $c->res->header( Location => $uri );
    $c->res->status(201); # created
}

1;

__END__

=head1 DISPATCH TABLE

    connect "rest/document/id/:id",
        { controller => "Acore::WAF::Controller::REST", action => "document" };
    connect "rest/document/path/:path",
        { controller => "Acore::WAF::Controller::REST", action => "document" };
    connect "rest/document",
        { controller => "Acore::WAF::Controller::REST", action => "new_document" };

=end
