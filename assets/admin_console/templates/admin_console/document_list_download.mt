?  my $c = $_[0];
?  for my $doc ( @{ $c->stash->{all_documents} } ) {
?=     YAML::Dump $doc->to_object;
?  }
