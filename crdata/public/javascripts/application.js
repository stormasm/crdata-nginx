// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function toggleCheckBoxes(el) {
  var checked = 0;
  if (el.checked == true) 
    checked = 1;
  $('select_form').getInputs('checkbox').each(function(e){ e.checked = checked });
}
