package Acore::Document;

use strict;
use warnings;
use Acore::Util  qw/ clone /;
use Scalar::Util qw/ blessed /;
use UNIVERSAL::require;
use Acore::DateTime;
use Any::Moose;
use Any::Moose 'Util::TypeConstraints';
use Carp;
use List::MoreUtils qw/ uniq /;
use B;

subtype 'DateTime'
    => as 'Object',
    => where { $_->isa($Acore::DateTime::DT_class) };

coerce 'DateTime'
    => from 'Str',
    => via { Acore::DateTime->parse_datetime($_) };

has id => (
    is => "rw",
);

has path => (
    is => "rw",
);

has content_type => (
    is      => "rw",
    default => "text/plain",
);

has tags => (
    is      => "rw",
    default => sub { [] },
);

has created_on => (
    is      => "rw",
    isa     => "DateTime",
    lazy    => 1,
    coerce  => 1,
    default => sub {
        $_[0]->{_created_on}
            ? Acore::DateTime->parse_datetime( $_[0]->{_created_on} )
            : Acore::DateTime->now;
    },
);

has updated_on => (
    is      => "rw",
    isa     => "DateTime",
    lazy    => 1,
    coerce  => 1,
    default => sub {
        $_[0]->{_updated_on}
            ? Acore::DateTime->parse_datetime( $_[0]->{_updated_on} )
            : Acore::DateTime->now;
    },
);

has xpath => (
    is         => "rw",
    isa        => "Data::Path",
    lazy_build => 1,
);

my $xpath_callback = {
    key_does_not_exist            => sub {},
    index_does_not_exist          => sub {},
    retrieve_index_from_non_array => sub {},
    retrieve_key_from_non_hash    => sub {},
};

sub _build_xpath {
    my $self = shift;
    require Data::Path;
    Data::Path->new( $self, $xpath_callback );
}

sub BUILD {
    my ($self, $obj) = @_;
    for my $n ( keys %$obj ) {
        $self->{$n} = $obj->{$n} unless exists $self->{$n};
    }
    $self;
}

sub unbless {
    my $b_obj = B::svref_2object( $_[0] );
    return    $b_obj->isa('B::HV') ? { %{ $_[0] } }
            : $b_obj->isa('B::AV') ? [ @{ $_[0] } ]
            : undef
            ;
}

sub to_object {
    my $self = shift;

    my $obj = clone $self;
    $obj->call_trigger("to_object");

    require Acore::DateTime;
    $obj->{created_on} = Acore::DateTime->format_datetime( $obj->created_on );
    $obj->{updated_on} = Acore::DateTime->format_datetime( $obj->updated_on );
    $obj->{_class}     = ref $self;
    $obj->{_id}        = delete $obj->{id} if $obj->{id};
    delete $obj->{$_} for qw/ xpath _created_on _updated_on /;

    return $obj->unbless;
}

sub from_object {
    my $class = shift;
    my $obj   = shift;
    return unless $obj->{_class};
    $obj->{_class}->require;
    $obj->{id} = delete $obj->{_id} if $obj->{_id};
    for ( qw/ created_on updated_on / ) {
        $obj->{"_$_"} ||= delete $obj->{$_};
    }
    $obj = $obj->{_class}->new($obj);

    $obj->call_trigger("from_object");
    $obj;
}

my $Triggers;
sub call_trigger {
    my ($self, $name, @args) = @_;
    my $class = blessed $self;
    for my $code (@{ $Triggers->{$name} || [] }) {
        $code->($self, @args);
    }
}

sub add_trigger {
    my $class = shift;
    while ( my ($name, $code) = ( shift, shift ) ) {
        last if !$name || !$code;
        $Triggers->{$name} ||= [];
        push @{ $Triggers->{$name} }, $code;
    }
}

sub as_string {
    my $self = shift;
    require Data::Dumper;
    local $Data::Dumper::Indent = 1;
    return Data::Dumper::Dumper($self);
}

sub param {
    my $self = shift;
    my $name = shift;

    return ( $name =~ /^\// ) ? $self->xpath->get($name)
                              : $self->{$name};
}

our %AUTOLOADED;
our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD =~ /::(\w+)$/ ? $1 : undef;

    return if (!defined $name) || ($name eq 'DESTROY');

    carp("$self has no method $name, AUTLOADed")
        unless $AUTOLOADED{$AUTOLOAD}++;

    if (@_) {
        $self->{$name} = shift;
    }
    $self->{$name};
}

sub update_from_hashref {
    my ($self, $obj) = @_;

    for my $n ( keys %$obj ) {
        $self->{$n} = $obj->{$n};
    }

    my $class = blessed $self;
    for my $n ( keys %$self ) {
        # 渡された hash ref に存在しない key の扱い
        # メソッド名の key は削除しない (ただし AUTOLOAD で生成されたものは除く)
        next if $self->can($n) && !$AUTOLOADED{"${class}::$n"};
        delete $self->{$n} unless exists $obj->{$n};
    }
    $self;
}

sub html_form_to_create {
    my $class = shift;

    my $tmpl = q{
? my ($c) = @_;
<fieldset>
  <legend>Content</legend>
  <div>
? if ($c->stash->{yaml_error_message}) {
    <p class="error">
      <?= $c->stash->{yaml_error_message} | html | html_line_break | raw ?>
    </p>
? }
    <label for="content">YAML</label>
    <textarea name="content" cols="60" rows="20">tags: []
</textarea>
  </div>
</fieldset>
};
}

sub html_form_to_update {
    my $self = shift;

    my $tmpl = q{
? my ($c, $doc) = @_;
<fieldset>
  <legend>Content</legend>
<?
   my $obj = $doc->to_object;
   delete $obj->{$_} for qw/ id _id _class content_type path updated_on created_on /;
?>
  <div>
? if ($c->stash->{yaml_error_message}) {
    <p class="error">
      <?= $c->stash->{yaml_error_message} | html | html_line_break | raw ?>
    </p>
? }
    <label for="content">YAML</label>
      <textarea name="content" cols="60" rows="20"><?= Acore::YAML::Dump($obj) ?></textarea>
  </div>
</fieldset>
};

}

sub validate_to_update {
    my ($self, $c) = @_;

    require Acore::YAML;
    my $obj = eval { Acore::YAML::Load( $c->req->param('content') . "\r\n" ) };
    if ($@ || !$obj) {
        $c->log->error("invalid YAML. $@");
        $c->form->set_error( content => "INVALID_YAML" );
        my $msg = $@;
        $msg =~  s{at .+? line \d+}{};
        $c->stash->{yaml_error_message} = $msg;
    }

    $self->update_from_hashref($obj);

    $self->{$_} = $c->req->param($_) for qw/ id path content_type /;
    $self;
}

sub validate_to_create {
    my ($class, $c) = @_;

    require Acore::YAML;
    my $obj  = eval { Acore::YAML::Load( $c->req->param('content') . "\r\n" ) };
    if ($@ || !$obj) {
        $c->log->error("invalid YAML. $@");
        $c->form->set_error( content => "INVALID_YAML" );
        my $msg = $@;
        $msg =~  s{at .+? line \d+}{};
        $c->stash->{yaml_error_message} = $msg;
    }
    $obj->{$_} = $c->req->param($_) for qw/ path content_type /;
    $class->new($obj);
}

sub Data::Path::set {
    my $self  = shift;
    my $xpath = shift;
    my $value = shift;

    my (undef, @nodes) = split /\//, $xpath;
    my $ref   = $self->{data};
    my $last  = pop @nodes;
    for my $n (@nodes) {
        if ( $n =~ m{\A(\w+)\[(\d+)\]\z} ) {
            $ref = $ref->{$1} ||= [];
            $ref = $ref->[$2] ||= {};
        }
        else {
            $ref = $ref->{$n} ||= {};
        }
    }
    if ( $last =~ m{\A(\w+)\[(\d+)\]\z} ) {
        $ref = $ref->{$1} ||= [];
        $ref = $ref->[$2]   = $value;
    }
    else {
        $ref->{$last} = $value;
    }
    $value;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
__END__

=head1 NAME

Acore::Document - document base class

=head1 SYNOPSIS

  package YourDocument;
  use Any::Moose;
  extends 'Acore::Document';
  has foo => (
     is => "rw",
  );

  $doc = YourDocument->new({
      path => "/foo/bar",
      foo  => "bar",
  });
  $acore->put_document($doc);

  $doc = Acore::Document->new({
    foo => {
        bar  => "baz",
        list => [ 1, 2, 3 ],
    }
  });
  $doc->xpath->get('/foo/bar');     # "baz"
  $doc->xpath->get('/foo/list[0]'); # 1
  $doc->xpath->set('/foo/bar' => $value); # $doc->{foo}->{bar} = $value

=head1 DESCRIPTION

Acore::Document is AnyCMS schema less document class.

=head1 ATTRIBUTES

=over 4

=item id

=item path

=item tags

=item content_type

=item created_on

=item updated_on

=item xpath

Data::Path object for xpath like accessing.

 $doc->xpath->get("/foo/bar");
 $doc->xpath->set("/foo/bar" => $value);

=item html_form_to_create

Returns HTML form template string (for Text::MicroTemplate) for using create form.

=item html_form_to_update

Returns HTML form template string (for Text::MicroTemplate) for using update form.

=back

=head1 METHODS

=over 4

=item new

Constractor.

=item to_object

Convert to plain object (hash ref). Called before Acore->put_document().

 $hash_ref = $doc->to_object;

=item from_object

Class method.

Convert from plain object (hash ref). Called after Acore->get_document().

 $doc = YourDocument->from_object($hash_ref);

=item validate_to_create($class, $c)

=item validate_to_update($self, $c)

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

L<Data::Path>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
