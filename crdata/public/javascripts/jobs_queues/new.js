$('visibility').observe('change', function() {
  if (this.value == 'share') {
    $('select_groups').show(); 
  } else {
    $('select_groups').hide(); 
  }
}); 
