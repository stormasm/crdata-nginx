$('show_automatic_node_link').observe('click', function(event) {
  $('manual_node').hide(); 
  $('automatic_node').show(); 
  $('node_type').value = 'automatic'
  Event.stop(event);
}); 

$('show_manual_node_link').observe('click', function(event) {
  $('manual_node').show(); 
  $('automatic_node').hide(); 
  $('node_type').value = 'manual'
  Event.stop(event);
}); 


$('hide_help_link').observe('click', function(event) {
  $('help_text').hide(); 
  $('help_link').show(); 
  Event.stop(event);
});

function show_help_link(event) {
  $('help_link').hide(); 
  $('help_text').show(); 
  Event.stop(event);
}


$('hide_help_link2').observe('click', function(event) {
  $('help_text2').hide(); 
  $('help_link2').show(); 
  Event.stop(event);
});

function show_help_link2(event) {
  $('help_link2').hide(); 
  $('help_text2').show(); 
  Event.stop(event);
}