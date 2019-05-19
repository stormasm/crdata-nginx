$('visibility').observe('change', function() {
  if (this.value == 'share') {
    $('select_groups').show(); 
    $('s3_credentials').show(); 
  } 
  else if (this.value == 'private') {
    $('s3_credentials').show(); 
    $('select_groups').hide(); 
  } else {
    $('select_groups').hide(); 
    $('s3_credentials').hide(); 
  }
}); 

