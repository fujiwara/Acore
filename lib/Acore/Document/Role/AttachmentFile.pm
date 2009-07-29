package Acore::Document::Role::AttachmentFile;
use strict;
use warnings;
use Any::Moose '::Role';
use Path::Class  qw/ file dir /;
use Scalar::Util qw/ blessed /;
use Carp;

requires 'attachment_root_dir';

has attachment_files => (
    is      => "rw",
    isa     => "ArrayRef",
    coerce  => 1,
    default => sub { [] },
);

Acore::Document->add_trigger(
    to_object => sub {
        my $self  = shift;
        return $self unless $self->can('attachment_files');
        my @files = map { "$_" } @{ $self->attachment_files };
        $self->attachment_files(\@files);
        $self;
    },
    from_object => sub {
        my $self  = shift;
        return $self unless $self->can('attachment_files');
        for my $file ( @{ $self->{attachment_files} } ) {
            $file = file($file);
        }
        $self;
    },
    delete => sub {
        my $self  = shift;
        return $self unless $self->can('attachment_files');
        $self->remove_attachment_file($_)
            for @{ $self->attachment_files };
        if ($self->id) {
            $self->attachment_dir->remove;
        }
    },
);

sub attachment_dir {
    my $self = shift;
    dir( $self->attachment_root_dir, $self->id );
}

sub has_attachment_files {
    my $self = shift;
    return @{ $self->attachment_files };
}

sub add_attachment_file {
    my $self = shift;
    my $arg  = shift;

    if ( blessed $arg && $arg->isa('Path::Class::File') ) {
        push @{ $self->attachment_files }, $arg;
        return $arg;
    }
    elsif ( ref $arg ) { # handle
        my $filename = shift || ($self->has_attachment_files + 1).".dat";
        my $dir = $self->attachment_dir;
        $dir->mkpath;
        my $file = $dir->file($filename);
        my $fh   = $file->openw or croak("Can't open $file. $!");
        my $buf;
        while ( read $arg, $buf, 4096 ) {
            $fh->print($buf);
        }
        $fh->close;
        push @{ $self->attachment_files }, $file;
        return $file;
    }
    else {
        croak("add_attachment_file: requires Path::Class::File object OR file handle");
    }
}

sub remove_attachment_file {
    my $self = shift;
    my $arg  = shift;

    my @remove_file;
    if ( blessed $arg && $arg->isa('Path::Class::File') ) {
        for my $file ( @{ $self->attachment_files } ) {
            if ( $file eq $arg ) {
                push @remove_file, $file;
                undef $file;
            }
        }
    }
    elsif ( $arg =~ /\A(\d+)\z/ ) {
        @remove_file = ( delete $self->attachment_files->[$1] );
    }
    for my $file (@remove_file) {
        $file->remove()
            or carp("Can't remove $file: $!");
    }
    $self->{attachment_files}
        = [ grep { $_ } @{ $self->{attachment_files} } ];
}

1;

__END__

__END__

=head1 NAME

Acore::Document::Role::AttachmentFile - role for attachment file

=head1 SYNOPSIS

  package YourDocument;
  use Any::Moose;
  extends 'Acore::Document';
  has attachment_root_dir => (
     is => "rw",
  );
  with 'Acore::Document::Role::AttachmentFile';

  $doc = YourDocument->new({ attachment_root_dir => "/path/to/dir" });
  $doc->add_attachment_file( $fh => "filename.ext" );
  $doc->add_attachment_file( Path::Class::file("/path/to/dir/file.txt") );
  $doc->attachment_dir;  # dir for store files

  @files = @{ $doc->attachment_files };

  $doc->remove_attachment_file(1); # remove $doc->attachment_file->[1];

=head1 DESCRIPTION

Acore::Document::Role::AttachmentFile is Role for attachment file.

=head1 REQUIRES

=over 4

=item attachment_root_dir

Directory to store attachment file.

  has attachment_root_dir => ( is => "rw" );

=back

=head1 METHODS

=over 4

=item attachment_files

Returns array ref of Path::Class::File instances.

=item attachment_dir

Returns Path::Class::Dir instance.

=item add_attachment_file

Add attachment file by filehandle or Path::Class::File instance.

  $doc->add_attachment_file( $fh => "filename.ext" );
  $doc->add_attachment_file( file("/path/to/dir/file.txt") );

=item remove_attachment_file

Remove attachment file by index or Path::Class::File instance.

  $doc->remove_attachment_file(0); # at first
  $doc->remove_attachment_file($_)
     for @{$doc->attachment_files};

=item has_attachment_files

Returns number of attachment files.

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
