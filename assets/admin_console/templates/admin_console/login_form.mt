? my $c = $_[0];
?=r $c->render_part("admin_console/header.mt");
<body>
  <form action="<?= $c->uri_for('login_form') ?>" method="post">
    username: <input type="text" name="name" size="20"/><br/>
    password: <input type="password" name="password" size="20"/><br/>
    <input type="submit" value="login"/>
  </form>
</body>
</html>
