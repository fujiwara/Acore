<?
  my $c = shift;
  my $quote = sub { local $_ = shift; s/"/""/g; qq{"$_"} };
  my %attrs;
  for my $user ( @{ $c->stash->{all_users} } ) {
      $attrs{$_} = 1 for $user->attributes;
  }
  my @attr = map { $quote->($_) } sort keys %attrs;
?>"name","password",<?= raw join(",", @attr) ?>
? for my $user ( @{ $c->stash->{all_users} } ) {
?     my @attr = map { $quote->( $user->attr($_) ) } sort keys %attrs;
?     my $name = $quote->( $user->name );
<?= raw $name ?>,<?= raw join(",", @attr) ?>
? }
