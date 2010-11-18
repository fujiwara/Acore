package Acore::WAF::Controller::AdminConsole;

use strict;
use warnings;
use Data::Dumper;
use List::MoreUtils qw/ uniq zip /;
use List::Util;
use Scalar::Util qw/ blessed /;
use utf8;

use Any::Moose;
with "Acore::WAF::Controller::Role::Locatable";

no Any::Moose;
__PACKAGE__->meta->make_immutable;

our $PermitRole = "AdminConsoleLogin";
our $Location;

sub _auto {
    my ($self, $c, $args) = @_;
    $self->set_location($c, $args);

    $c->res->header(
        "pragma"         => "no-cache",
        "Cache-Control" => "no-cache",
    ) if $args->{action} ne "static";

    1;
}

sub is_logged_in {
    my ($self, $c) = @_;

    if ( $c->user && $c->user->has_role($PermitRole) ) {
        $c->log->debug("user logged in.");
        if ( $c->req->method eq "POST"
          && $c->req->param('sid') ne $c->session->session_id )
        {
            $c->error( 500 => 'CSRF detacted.' );
        }
        return 1;
    }
    $c->log->debug( $c->user );

    $c->redirect( $c->uri_for("/$Location/login_form") );
    $c->detach();
}

sub _allow_eval {
    my ($self, $c) = @_;
    if ( $c->config->{$Location}->{disable_eval_functions} ) {
        $c->error( 403 => "eval functions is not allowed by config." );
    }
    1;
}

sub index {
    my ($self, $c) = @_;
    my @all_users = $c->acore->search_users_has_role($PermitRole);
    if (@all_users) {
        $c->redirect( $c->uri_for("/$Location/login_form") );
    }
    else {
        $c->redirect( $c->uri_for("/$Location/setup_at_first") );
    }
}

sub static {
    my ($self, $c, $args) = @_;

    $c->debug(0);
    $c->log->disabled(1);

    my ($path) = grep qr{/admin_console/}, @{ $c->config->{include_path} };
    my $file = Path::Class::file( $path, "../static/", $args->{filename} );
    $c->serve_static_file($file);
}

sub login_form_GET {
    my ($self, $c) = @_;
    $c->render("$Location/login_form.mt");
}

sub login_form_POST {
    my ($self, $c) = @_;

    my $r = $c->req;
    if ( $c->login( $r->param('name'), $r->param('password') ) ) {
        $c->log->info("login succeeded.");
        $c->redirect( $c->uri_for("/$Location/menu") ) ;
    }
    else {
        $c->form->set_error('login' => "FAILED");
        $c->render("$Location/login_form.mt");
    }
}

sub logout {
    my ($self, $c) = @_;
    $c->logout;
    $c->redirect( $c->uri_for("/$Location/login_form") );
}

sub menu_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->render("$Location/menu.mt");
}

sub setup_at_first_GET {
    my ($self, $c) = @_;

    my @all_users = $c->acore->search_users_has_role($PermitRole);
    if (@all_users) {
        $c->stash->{user_exists} = 1;
    }

    $c->render("$Location/setup_at_first.mt");
}

sub setup_at_first_POST {
    my ($self, $c) = @_;

    $c->form->check(
        name      => [qw/ NOT_NULL ASCII /],
        password1 => [qw/ NOT_NULL ASCII /],
        { password => [qw/password1 password2/]} => ['DUP'],
    );
    if ($c->form->has_error) {
        $c->render("$Location/setup_at_first.mt");
        $c->fillform;
        return;
    }

    my $user = $c->acore->create_user({
        name => $c->req->param('name'),
    });
    $user->add_role($PermitRole);
    $user->set_password($c->req->param('password1'));
    $c->acore->save_user($user);

    $c->render("$Location/setup_done.mt");
}

sub user_list_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    $c->stash->{all_users} = [ $c->acore->all_users ];
    $c->render("$Location/user_list.mt");
}

sub user_download_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    $c->stash->{all_users} = [ $c->acore->all_users ];

    $c->res->header(
        "Content-Type"        => "text/csv; charset=utf-8",
        "Content-Disposition" => "attachment; filename=users.csv",
    );
    $c->render("$Location/user_download.mt");
}

sub user_form_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    my $name = $c->req->param('name');
    $c->stash->{user} = $c->acore->get_user({ name => $name })
        or $c->error( 404, "user name='$name' not found" );

    $c->render("$Location/user_form.mt");
}

sub user_form_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    my $name = $c->req->param('name');
    my $user = $c->acore->get_user({ name => $name })
        or $c->error( 404, "user name='$name' not found" );

    if ( $c->req->param('password1') ne '' ) {
        $c->form->check(
            password1 => [qw/ NOT_NULL ASCII /],
            { password => [qw/password1 password2/]} => ['DUP'],
        );
        if ($c->form->has_error) {
            $c->stash->{user} = $user;
            $c->render("$Location/user_form.mt");
            $c->fillform;
            return;
        }
        $user->set_password($c->req->param('password1'));
    }

    my @roles = grep { /\A[\w:]+\z/ } $c->req->param('roles');
    $user->roles(\@roles);

    # 追加 attributes
    my @attr = grep { /\A_attr_(.\w+)/ } $c->req->param;
    for my $attr ( map { /\A_attr_(\w+)/; $1 } @attr ) {
        $user->attr( $attr => $c->req->param("_attr_${attr}") );
    }

    # 削除 attributes
    @attr = grep { /./ } split /,/, $c->req->param('remove_attrs');
    for my $attr ( @attr ) {
        delete $user->{$attr};
    }

    $c->acore->save_user($user);

    $c->flash->set( user_saved => 1 );
    $c->redirect(
        $c->uri_for("/$Location/user_form", { name => $name })
    );
}

sub user_create_form_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->render("$Location/user_create_form.mt");
}

sub user_create_form_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    my $name = $c->req->param('name');
    my $user = $c->acore->get_user({ name => $name });
    if ($user) {
        $c->form->set_error( name => 'EXISTS' );
    }

    $c->form->check(
        password1 => [qw/ NOT_NULL ASCII /],
        { password => [qw/password1 password2/]} => ['DUP'],
    );
    if ($c->form->has_error) {
        $c->render("$Location/user_create_form.mt");
        $c->fillform;
        return;
    }

    $user = $c->acore->create_user({
        name => $name,
    });
    my @roles = grep { /\A[\w:]+\z/ } $c->req->param('roles');
    $user->roles(\@roles);
    $user->set_password( $c->req->param('password1') );
    $c->acore->save_user($user);

    $c->flash->set( user_saved => 1 );
    $c->redirect(
        $c->uri_for("/$Location/user_form", { name => $name })
    );
}

sub user_DELETE {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    my $name = $c->req->param('name');
    my $user = $c->acore->get_user({ name => $name })
        or $c->error( 404, "user name='$name' not found" );

    if ($c->user->name eq $user->name) {
        $c->error( 500, "Can't delete user logged in." );
    }

    $c->acore->delete_user($user);

    $c->render("$Location/user_deleted.mt");
}


sub user_upload_POST {
    my ($self, $c) = @_;
    require Text::CSV_XS;

    $c->forward( $self => "is_logged_in" );
    my $upload = $c->req->upload('upload_file')
        or $c->error(400);

    my $fh = $upload->fh;
    binmode $fh, ":utf8";

    my $csv = Text::CSV_XS->new({ binary => 1 });
    my $header_ref = $csv->getline($fh);

    my $acore = $c->acore;
    my $imported = 0;

    $acore->txn_do( sub {
        while ( my $col_ref = $csv->getline($fh) ) {
            my $value = +{ zip @$header_ref, @$col_ref };
            my $name = delete $value->{name};
            next unless defined $name;
            my $user = $acore->get_user({ name => $name })
                    || $acore->create_user({ name => $name });

            my $new_password = delete $value->{password};
            $user->set_password( $new_password )
                if defined $new_password;
            for my $key ( keys %$value ) {
                $user->attr( $key => $value->{$key} );
            }
            $acore->save_user($user);
            $imported ++;
        }
    });
    $c->stash->{imported} = $imported;
    $c->render("$Location/user_upload.mt");
}

sub document_list_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    my $limit  = int( $c->req->param('limit') || 20 );
    my $page   = int( $c->req->param('page')  || 1  );
    my $offset = ( $page - 1 ) * $limit;

    $c->forward( $self => "_document_add_keys" );

    my $type  = $c->req->param('type');
    my $query = $c->req->param('q');
    if ( $type =~ /\A(?:path|tags)\z/ && $query ne '' ) {
        $c->stash->{all_documents} = [
            $c->acore->search_documents({
                $type         => $query,
                offset        => $offset,
                limit         => $limit,
                value_reverse => $c->req->param('reverse') ? 1 : 0,
            }),
        ];
    }
    elsif ( $type && $query ne '' ) {
        my @args = ($c->req->param('match') eq 'start_with')
                 ? ( key_start_with => $query )
                 : ( key            => $query );
        $c->stash->{all_documents} = [
            $c->acore->search_documents({
                view   => "${type}/all",
                offset => $offset,
                limit  => $limit,
                @args,
            }),
        ];
    }
    else {
        $c->stash->{all_documents} = [
            $c->acore->all_documents({
                offset  => $offset,
                limit   => $limit,
                reverse => 1,
            }),
        ];
    }
    $c->stash->{offset} = $offset;
    $c->stash->{limit}  = $limit;
    $c->stash->{page}   = $page;

    if ( $c->req->param('download') ) {
        $c->render("$Location/document_list_download.mt");
        $c->res->content_type('application/x-yaml; charset=utf-8');
    }
    else {
        $c->render("$Location/document_list.mt");
        $c->fillform;
    }
}

sub _document_add_keys {
    my ($self, $c) = @_;

    return unless $c->req->param('update_keys');
    my @keys = grep /./, $c->req->param('keys');
    $c->session->set( document_show_keys => \@keys );
    $c->req->param('keys' => @keys);
}

sub _get_document {
    my ($self, $c, $id) = @_;

    $id ||= $c->req->param('id');
    my $doc = $c->acore->get_document({ id => $id });
    $c->error( 404 => "document not found." )
        unless $doc;
    $doc;
}

sub document_form_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    $c->stash->{document} = $c->forward( $self => "_get_document" );

    $c->render("$Location/document_form.mt");
}

sub document_form_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    my $doc = $c->forward( $self => "_get_document" );
    my $old_doc = Acore::Util::clone($doc);
    $c->stash->{document} = $doc;

    $c->form->check(
        id   => [qw/ NOT_NULL ASCII /],
        path => [qw/ NOT_NULL ASCII /],
    );
    $doc->validate_to_update($c);

    if ( $c->form->has_error ) {
        $doc->call_trigger('from_object');
        $c->render("$Location/document_form.mt");
        $c->fillform;
        return;
    }
    $doc->$_( $c->req->param($_) ) for qw/ path content_type /;

    $c->acore->put_document($doc, { update_timestamp => 0 });
    if ( $doc->can('execute_on_update') ) {
        $doc->execute_on_update($c, $old_doc);
    }

    $c->flash->set( document_saved => 1 );
    if ( $c->req->param('.send') ) {
        $c->forward( $self, "_document_send", $doc );
    }
    $c->redirect(
        $c->uri_for(
            "/$Location/document_form",
            { id => $doc->id, _t => time }
        )
    );
}

sub document_create_form_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    my $classes = $c->config->{$Location}->{document_classes};
    $c->log->debug("document_classes: @$classes") if $classes;
    my $class = $c->req->param('_class')
             || ( (ref $classes eq 'ARRAY') ? $classes->[0]
                                          : "Acore::Document" );
    if ( !$class->use || !$class->isa('Acore::Document') ) {
        die "Invalid class $@";
    }
    $c->stash->{_class} = $class;

    $c->render("$Location/document_create_form.mt");
}

sub document_create_form_POST {
    my ($self, $c) = @_;

    my $req  = $c->req;
    my $form = $c->form;
    $c->forward( $self => "is_logged_in" );

    my $class = $req->param('_class');
    if ( !$class->require || !$class->isa('Acore::Document') ) {
        $c->log->error($@);
        $form->set_error( _class => "INVALID" );
    }
    $c->stash->{_class} = $class;

    my $doc = $class->validate_to_create($c);
    if ( !defined $doc->{path} ) {
        $form->check(
            path => [qw/ NOT_NULL ASCII /],
        );
        $doc->path( $req->param('path') );
    }

    my $id = $req->param("id");
    if ( defined $id && $id ne "" ) {
        if ( $id =~ /\s/ ) {
            $form->set_error( id => "INCLUDE_WHITE_SPACE" );
        }
        my $exists = $c->acore->get_document({ id => $id });
        if ($exists) {
            $form->set_error( id => "EXISTS" );
        }
        else {
            $doc->id($id);
        }
    }

    if ( $c->form->has_error || !$doc ) {
        $c->render("$Location/document_create_form.mt");
        $c->fillform;
        return;
    }
    for my $key ( qw/ path content_type / ) {
        $doc->$key( $c->req->param($_) )
            if !defined $doc->{$key};
    }

    $doc = $c->acore->put_document($doc);
    if ( $doc->can('execute_on_create') ) {
        $doc->execute_on_create($c);
    }

    $c->flash->set( document_saved => 1 );
    $c->redirect(
        $c->uri_for("/$Location/document_form", { id => $doc->id, _t => time } )
    );
}

sub document_DELETE {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    my $acore = $c->acore;
    $acore->txn_do(
        sub {
            for my $id ( $c->req->param('id') ) {
                my $doc = $acore->get_document({ id => $id });
                next unless $doc;
                $acore->delete_document($doc);
                if ( $doc->can('execute_on_delete') ) {
                    $doc->execute_on_delete($c);
                }
            }
        });

    $c->render("$Location/document_deleted.mt");
}

sub document_attachment_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    my $doc = $c->forward( $self => "_get_document" );

    if ( my $upload = $c->req->upload('attachment_file') ) {
        my $filename = $upload->filename;
        $filename = Encode::decode_utf8($filename);
        $filename = (split /\\/, $filename)[-1] if $filename =~ /\\/;
        $filename = URI::Escape::uri_escape_utf8($filename);

        $c->log->info( "upload filename: $filename" );
        $doc->add_attachment_file( $upload->fh => $filename );
        $c->acore->put_document($doc, { update_timestamp => 0 });
    }
    else {
        $c->error( 204 => "upload file not found" );
    }

    $c->flash->set( attachment_added => 1 );
    $c->redirect(
        $c->uri_for("/$Location/document_form", { id => $doc->id, _t => time } )
    );
}

sub document_attachment_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    my $doc = $c->forward( $self => "_get_document" );
    my $n   = int $c->req->param('n');
    my $file = $doc->attachment_files->[$n]
        or $c->error( 404 => "attachment file $n is not found" );

    my $filename = $c->req->user_agent =~ /MSIE/
                 ? $file->basename   # uri escaped
                 : URI::Escape::uri_unescape($file->basename);
    $c->res->header( "Content-Disposition" => "inline; filename=$filename" );
    $c->serve_static_file($file);
}

sub document_attachment_DELETE {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    my $doc = $c->forward( $self => "_get_document" );
    my $n   = int $c->req->param('n');
    my $file = $doc->attachment_files->[$n]
        or $c->error( 404 => "attachment file $n is not found" );
    $doc->remove_attachment_file($n);
    $c->acore->put_document($doc, { update_timestamp => 0 });

    $c->flash->set( attachment_deleted => 1 );
    $c->redirect(
        $c->uri_for("/$Location/document_form", { id => $doc->id, _t => time } )
    );
}

sub doc_class_GET {
    my ($self, $c) = @_;
    $c->forward( $self => "is_logged_in" );
    $c->render("$Location/doc_class.mt");
}

sub _doc_class_validate {
    my ($self, $c) = @_;

    $c->form->check(
        class => [['REGEX', qr/\A[A-Z]([_a-zA-Z0-9]+|::)*[_a-zA-Z0-9]+\z/]],
    );

    my $class = $c->req->param('class');
    if ($c->form->has_error) {
        $c->render("$Location/doc_class.mt");
        $c->fillform;
        $c->detach;
    }
    $c->stash->{class} = $class;
    ( $c->stash->{class_filename} = $class ) =~ s{::}{_}g;
    1;
}

sub doc_class_POST {
    my ($self, $c) = @_;
    $c->forward( $self => "is_logged_in" );
    $c->forward( $self => "_doc_class_validate" );

    if ($c->req->param('download-pm')) {
        my $html = $c->req->param('form-html');
        my @names = ($html =~ m/name=['"]\/(\w+)['"]/g );
        $c->stash->{names} = [ uniq(@names) ];

        $c->render("$Location/doc_class_pm.mt");
        $c->res->header(
            "Content-Type"        => "text/plain",
            "Content-Disposition" =>
                sprintf("attachment; filename=%s.pm", $c->stash->{class_filename}),
        );
    }
    elsif ($c->req->param('download-tmpl')) {
        my $body = $c->render_part("$Location/doc_class_tmpl.mt");
        $body =~ s/\r*\n/\n/g;
        $c->res->body( $body );
        $c->res->header(
            "Content-Type"        => "text/plain",
            "Content-Disposition" =>
                sprintf("attachment; filename=%s_create_form.mt", $c->stash->{class_filename}),
        );
    }
}

sub view_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->forward( $self => "_allow_eval" );

    my @design = $c->acore->storage->document->all_designs;
    $c->stash->{all_views} = [
        map { $_->{value}->{id} = $_->{id}; $_->{value} } @design
    ];
    if ( $c->req->param('backup') ) {
        $c->res->content_type('text/plain; charset=utf-8');
        $c->res->header(
            "Content-Disposition" => "attachment; filename=restore_views.pl"
        );
        $c->render("$Location/view_backup.mt");
    }
    else {
        $c->render("$Location/view.mt");
    }
}

sub view_form_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->forward( $self => "_allow_eval" );

    my $id = $c->req->param('id');
    my $design = $c->acore->storage->document->get($id)
        or $c->error( 404 => "design not found" );
    $c->stash->{design} = $design;
    $c->render("$Location/view_form.mt");
}

sub view_form_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->forward( $self => "_allow_eval" );

    $c->form->check(
        id => [['REGEX', qr{\A_design/\w+\z}]],
    );

    my $id     = $c->req->param('id');
    my $design = $c->acore->storage->document->get($id)
              || {
                    _id   => $id,
                    views => { all => { map => "", reduce => "" } },
                 };

    for my $view ( $c->req->param('views') ) {
        $c->form->check(
            "${view}_name" => ['NOT_NULL', 'ASCII'],
        );
    TYPE:
        for my $type (qw/ map reduce /) {
            my $code = $c->req->param("${view}_${type}");
            next TYPE unless $code;
            my $sub = eval $code;     ## no critic
            if ($@) {
                $c->form->set_error( "${view}_${type}" => 'SYNTAX_ERROR' );
            }
            elsif (ref $sub ne 'CODE') {
                $c->form->set_error( "${view}_${type}" => 'NOT_CODE_REF' );
            }
            else {
                $design->{views}->{$view}->{$type} = $code;
            }
        }
    }
    if ($c->form->has_error) {
        $c->stash->{design} = $design;
        $c->render("$Location/view_form.mt");
        return $c->fillform;
    }

    $c->acore->txn_do(
        sub {
            my $backend = $c->acore->storage->document;
            $backend->put($design);
        });

    $c->flash->set( view_saved => 1 );
    $c->redirect(
        $c->uri_for(
            "/$Location/view_form",
            { id => $design->{_id}, _t => time },
        )
    );
}

sub view_form_DELETE {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->forward( $self => "_allow_eval" );

    my $id = $c->req->param('id');
    my $design = $c->acore->storage->document->get($id)
        or $c->error( 404 => "design not found" );

    $c->acore->storage->document->delete($design->{_id});
    $c->render("$Location/view_deleted.mt");
}

sub view_create_form_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->forward( $self => "_allow_eval" );

    my $map = q{
sub {
    my ($obj, $emit) = @_;
    # $emit->( $key, $value );
}
};
    my $design = {
        _id   => "",
        views => { all => { map => $map, reduce => "" } },
    };
    $c->stash->{design} = $design;
    $c->render("$Location/view_form.mt");
}


sub view_test_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->forward( $self => "_allow_eval" );
    require JSON;

    my $map  = $c->forward( $self => "_eval_code", $c->req->param('map') );
    my $pair = $c->forward( $self => "_do_map", $map );
    if ( $c->req->param('reduce') ) {
        my $reduce =
            $c->forward( $self => "_eval_code", $c->req->param('reduce') );
        $pair = $c->forward( $self => "_do_reduce", $reduce, @$pair );
    }
    $c->stash->{pairs} = $pair;
    $c->render("$Location/view_test.mt");
}

sub _eval_code {
    my ($self, $c, $code) = @_;

    $code = eval $code;  ## no critic
    if ($@) {
        $c->res->body("Error in eval map.: $@");
        $c->detach;
    }
    if (ref $code ne 'CODE') {
        $c->res->body("not CODE ref.");
        $c->detach;
    }
    $code;
}

sub _do_map {
    my ($self, $c, $map) = @_;

    my @pair;
    my $emit = sub {
        push @pair, [ $_[0], $_[1] ];
    };
    my @docs = $c->acore->all_documents({ limit => 40 });
    for my $doc (@docs) {
        eval {
            $map->( $doc->to_object, $emit );
        };
        if ($@) {
            return $c->res->body("Error at mapping.: $@");
        }
    }
    [ sort { $a->[0] cmp $b->[0] } @pair ];
}

sub _do_reduce {
    my ($self, $c, $reduce, @pair) = @_;

    my @result;
    my $pre_key = $pair[0]->[0];
    my @pre_values;
    for my $pair (@pair) {
        my ($key, $value) = @$pair;
        if ($key ne $pre_key) {
            my $result = eval { $reduce->( $pre_key, \@pre_values ) };
            if ($@) {
                $c->res->body("Error at reducing.: $@");
                $c->detach;
            }
            push @result, [ $pre_key, $result ];
            $pre_key    = $key;
            @pre_values = ();
        }
        push @pre_values, $value;
    }

    my $result = eval { $reduce->( $pre_key, \@pre_values ) };
    if ($@) {
        return $c->res->body("Error at reducing.: $@");
    }
    push @result, [ $pre_key, $result ];

    \@result;
}

sub upload_document_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->render("$Location/upload_document.mt");
}

sub upload_document_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );

    my $upload = $c->req->upload('file');
    my $loader = $c->acore->document_loader;
    eval {
        $loader->check_format( $upload->fh );
    };
    if ($@) {
        $c->form->set_error( exception => $@ );
        $c->render("$Location/upload_document.mt");
        return;
    }

    seek( $upload->fh, 0, 0 );
    eval {
        $c->acore->txn_do(
            sub {
                $loader->load( $upload->fh );
            }
        );
    };
    if ($@) {
        $c->form->set_error( exception => $@ );
    }
    if ( $loader->has_error ) {
        for my $error ( @{ $loader->errors } ) {
            $c->form->set_error( loader => $error );
        }
    }
    else {
        $c->stash->{notice}
            = sprintf "%d 件の Document が投入されました", $loader->loaded;
    }

    $c->render("$Location/upload_document.mt");
}

sub convert_all_GET {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->forward( $self => "_allow_eval" );

    $c->render("$Location/convert_all.mt");
}

sub convert_all_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->forward( $self => "_allow_eval" );

    my $code = $c->forward( $self => "_eval_code", $c->req->param('code') );

    my $converted = 0;
    my $offset    = 0;
    my $acore     = $c->acore;

    $acore->txn_do(
        sub {
        CONVERT:
            while (1) {
                my @docs = $c->acore->search_documents({
                    path   => $c->req->param('path'),
                    offset => $offset,
                    limit  => 100,
                });
                last CONVERT unless @docs;
                $offset += 100;

            DOCS:
                for my $doc (@docs) {
                    my $res = $code->($doc);
                    if ( ref $res ) {
                        $acore->put_document($res, { update_timestamp => 0 });
                        $converted++;
                    }
                }
            }
        });

    $c->stash->{converted} = $converted;
    $c->render("$Location/convert_done.mt");
}

sub convert_test_POST {
    my ($self, $c) = @_;

    $c->forward( $self => "is_logged_in" );
    $c->forward( $self => "_allow_eval" );

    my $code = $c->forward( $self => "_eval_code", $c->req->param('code') );

    my @docs = $c->acore->search_documents({
        path  => $c->req->param('path'),
        limit => 20,
    });
    my @pair;

    for my $doc (@docs) {
        my $old = Acore::Util::clone($doc);
        my $new = eval { $code->($doc) };
        if ($@) {
            return $c->res->body("Error in processing: $@");
        }
        push @pair, [
            $old->to_object,
            (blessed $new && $new->can('to_object')) ? $new->to_object
          : (ref $new)                               ? $new
          :                                            "-"
        ];
    }
    $c->stash->{pair} = \@pair;

    $c->render("$Location/convert_test.mt");
}

sub explorer_GET {
    my ($self, $c, $args) = @_;
    $c->forward( $self => "is_logged_in" );
    $c->render("$Location/explorer.mt");
}

sub explorer_tree_POST {
    my ($self, $c, $args) = @_;

    $c->req->param( sid => $c->session->session_id ); # XXX
    $c->forward( $self => "is_logged_in" );

    my $dir      = $c->req->param("dir");
    my $full_dir = $c->path_to($dir);
    my $root     = $c->path_to(".");

    my (@folders, @files);
    my $total = 0;
    for my $file ( $full_dir->children ) {
        $total++;
        if ( $file->is_dir ) {
            push (@folders, $file);
        } else {
            push (@files, $file);
        }
    }
    return if $total == 0;

    $c->stash->{folders} = \@folders;
    $c->stash->{files}   = \@files;
    $c->stash->{root}    = $root;

    $c->render("$Location/explorer_tree.mt");
}

sub explorer_file_info_GET {
    my ($self, $c, $args) = @_;

    $c->forward( $self => "is_logged_in" );

    my $name = $c->req->param("file");
    my $file = $c->path_to($name);
    if (! -e $file or $name =~ /\.\./ or $file->is_dir ) {
        $c->log->error("$file is not exists or is dir.");
        return;
    }

    require Acore::MIME::Types;
    my $mtime = Acore::DateTime->from_epoch( epoch => $file->stat->mtime );
    my $ext   = $file->basename =~ /\.(\w+)$/ ? lc $1 : "";
    my $info = {
        mtime    => "$mtime",
        size     => -s $file,
        filename => $c->req->param("file"),
        ext      => $ext,
        type     => Acore::MIME::Types->mime_type($ext) || "",
        editable => -w $file,
    };
    if ( $c->req->param('body') && $info->{size} <= 1024 * 1024 ) {
        $info->{body} = Encode::decode_utf8( $file->slurp );
    }
    $c->res->content_type('application/json; charset=utf-8');
    $c->res->body( JSON->new->encode($info) );
}

sub _explorer_get_file {
    my ($self, $c, $args) = @_;

    my $name = $c->req->param("file");
    my $file = $c->path_to($name);
    $c->error(404) if (! -e $file or $name =~ /\.\./ or $file->is_dir );
    $file;
}

sub explorer_download_file_GET {
    my ($self, $c, $args) = @_;

    $c->forward( $self => "is_logged_in" );
    my $file = $c->forward( $self => "_explorer_get_file" );

    $c->res->header(
        "Content-Disposition"
            => "attachment; filename=" . $file->basename
        );
    $c->serve_static_file($file);
}

sub explorer_save_file_POST {
    my ($self, $c, $args) = @_;

    $c->forward( $self => "is_logged_in" );
    my $file = $c->forward( $self => "_explorer_get_file" );
    {
        my $fh = $file->openw or $c->error( 405 => "permission denied" );
        my $body = $c->req->param('body');
        $fh->print( Encode::encode_utf8($body) );
    }
    $c->req->param( body => undef );
    $c->forward( $self => "explorer_file_info_GET" );
}

sub document_api_POST {
    my ($self, $c, $args) = @_;
    require JSON;
    require Acore::Document;
    my $req = $c->request;

    my $self_key = $c->config->{admin_console}->{api_key};
    if (!defined $self_key || $self_key eq "") {
        $c->error( 406 => "not acceptable" );
    }

    if ( my $ips = $c->config->{admin_console}->{api_allow_ips} ) {
        require Net::CIDR::Lite;
        my $cidr = Net::CIDR::Lite->new;
        $cidr->add($_) for @$ips;
        unless ( $cidr->find($req->address) ) {
            $c->error(
                403 => sprintf("%s is not allowed.", $req->address)
            );
        }
    }

    my $req_key = $req->header("api-key");
    if (!defined $req_key || $req_key ne $self_key ) {
        $c->error( 400 => "invalid api_key" );
    }

    my $body = Encode::decode_utf8( $req->raw_body );
    my $json = JSON->new;
    my $obj  = eval { $json->decode($body) };
    if ( $@ || !$obj || ref $obj ne "HASH" ) {
        $c->error( 400 => "Can't decode json. $@" );
    }
    my $doc = Acore::Document->from_object($obj);
    $c->acore->put_document($doc);

    $c->res->body("ok");
}

sub _document_send {
    my ($self, $c, $doc) = @_;
    my $send_to = $c->config->{admin_console}->{send_to} or return;
    require LWP::UserAgent;
    require HTTP::Request;

    my $json = Encode::encode_utf8(
        JSON->new->encode( $doc->to_object )
    );
    my $req = HTTP::Request->new( POST => $send_to->{uri} );
    $req->header( "api-key" => $send_to->{api_key} );
    $req->content($json);

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    my $res = $ua->request($req);

    if ($res->is_success) {
        $c->flash->{document_sent} = 1;
    }
    else {
        $c->flash->{document_sent_error} = $res->status_line;
    }
}

1;

__END__

=head1 DISPATCH TABLE

 connect "admin_console/",                 to bundled "AdminConsole" => "index";
 connect "admin_console/static/:filename", to bundled "AdminConsole" => "static";
 connect "admin_console/:action",          to bundled "AdminConsole";

=head1 CONFIG

 admin_console:
   document_classes:
     - MyDocument
     - FileDocument
     - Acore::Document
   disable_eval_functions: 0
   css_path: "/static/override.css"
   api_key: "SECRET KEY for myself"
   api_allow_ips:
     - 127.0.0.1/32
     - 192.168.0.0/24
   send_to:
     name: Remote Server
     uri:  http://remote.example.com/admin_console/document_api
     api_key: "SECRET KEY for remote"

=over 4

=item document_classes: []

Document classes for selection in document_form.

=item disable_eval_functions: 0|1

default 0

=item css_path: "/path/to/css"

Additional css path. for $c->uri_for()

=item api_key

API key for document_api. If it not set, document_api is disabled.

=item api_allow_ips

Allowed IP address ranges for document_api.

=item send_to

Remote Acore document_api info.

=over 4

=item name

String for display in admin_console/document_form

=item uri

Remote document_api URI.

=item api_key

Remote Acore API key.

=back

=back
