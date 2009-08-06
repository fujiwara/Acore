<?= raw "<s>" | html ?>
<?= raw "あいう" | uri ?>
<?= raw "あいう" | replace("あ", "A") ?>
<?= raw "<s>" | html | uri ?>
<?= raw "<s>\n<s>" | html | html_line_break ?>
