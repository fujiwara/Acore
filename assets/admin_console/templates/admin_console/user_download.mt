<?
  my $c = shift;
  my $quote = sub { local $_ = shift; s/"/""/g; qq{"$_"} };
  my %attrs;
  for my $user ( @{ $c->stash->{all_users} } ) {
      $attrs{$_} = 1 for $user->attributes;
  }
  my @attr = map { $quote->($_) } sort keys %attrs;
?>"name",<?=r \@attr | join(",") ?>
? for my $user ( @{ $c->stash->{all_users} } ) {
?     my @attr = map { $quote->( $user->attr($_) ) } sort keys %attrs;
?     my $name = $quote->( $user->name );
<?=r $name ?>,<?=r \@attr | join(",") ?>
? }
