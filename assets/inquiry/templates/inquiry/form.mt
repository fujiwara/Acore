<?
  my $c        = shift;
  my $location = location();
?>
<form action="<?= $c->uri_for(qq{$location/confirm}) ?>" method="post">
? if ( $c->form->has_error ) {
    <p>入力内容を確認してください</p>
      <ul>
?   for my $msg ( $c->form->get_error_messages ) {
        <li><?= $msg ?></li>
?   }
      </ul>
? }
  お名前 <input type="text" size="20" name="<?= $location ?>/name" /><br/>
  問い合わせ内容<br/>
  <textarea name="<?= $location ?>/body" rows="10" cols="40"></textarea>
  <br/>
  <input type="submit" value="確認画面へ"/>
? if ($c->can('session')) {
  <input type="hidden" name="sid" value="<?= $c->session->session_id ?>" />
? }
</form>

