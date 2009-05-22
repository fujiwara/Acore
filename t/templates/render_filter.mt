<?=r "<s>" | html ?>
<?=r "あいう" | uri ?>
<?=r "あいう" | replace("あ", "A") ?>
<?=r "<s>" | html | uri ?>
<?=r "<s>\n<s>" | html | html_line_break ?>
