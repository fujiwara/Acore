$('.flash-message')
  .css({ cursor: "pointer" })
  .click( function() {
    $(this).hide("fast");
  });
