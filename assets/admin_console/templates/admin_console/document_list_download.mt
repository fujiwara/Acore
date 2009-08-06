?  my $c = $_[0];
?  for my $doc ( @{ $c->stash->{all_documents} } ) {
?= raw    YAML::Dump $doc->to_object;
?  }
