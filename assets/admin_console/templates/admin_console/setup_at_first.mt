? my $c = $_[0];
?=r $c->render_part("admin_console/header.mt");
<body>
  <form action="setup_at_first" method="post">
    password: <input type="password" name="password" size="20"/><br/>
    <input type="submit" value="create root user"/>
  </form>
</body>
</html>
