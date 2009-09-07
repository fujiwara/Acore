? my $c        = shift;
? my $location = location();
? $c->renderer->wrapper_file("$location/wrapper.mt", $c)->(sub {

<form action="<?= $c->uri_for(qq{$location/finish}) ?>" method="post">
<p>以下の内容で送信してよろしいですか?</p>
  お名前 : <?= $c->req->param("$location/name") ?><br/>
  問い合わせ内容 : <br/>
  <pre style="border: 1px solid #000; width: 40em;"><?= $c->req->param("$location/body") ?></pre>
? for my $n ( $c->req->param ) {
  <input type="hidden" name="<?= $n ?>" value="<?= $c->req->param($n) ?>"/>
? }
  <input type="submit" value="送信する"/>
  <input type="submit" value="入力画面へ戻る" name="back" />
</form>

? });
