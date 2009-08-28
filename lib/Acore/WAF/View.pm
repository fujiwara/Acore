package Acore::WAF::View;

1;

__END__

=head1 NAME

Acore::WAF::View - empty class (POD only)

=head1 SYNOPSYS

 package YourApp::View::Foo;
 use Any::Moose;  # if require instantination
 sub setup {
     my ($self, $c) = @_;
     # setup yourself...
 }
 sub process {
     my ($self, $c, @args) = @_;
     # process view
 }

 package YourApp::Controller::Bar;
 sub bar {
     my ($self, $c, $args) = @_;
     $c->forward( $c->view("Foo") => "process", @args );
 }

