module RScriptsHelper

  # Get r_script actions  
  def get_r_script_actions(record)
    if current_user and current_user.groups.default.first.r_scripts.include?(record)
      link_to('Edit', edit_r_script_path(record)) + 
      link_to('Destroy', record, :confirm => 'Are you sure you want to delete this record?', :method => :delete)
    end
  end

  # Get options for enumeration script parameter type
  def get_enum_options(min_value, max_value, increment_value)
    i = min_value
    enum = Array.new
    while i <= max_value
      enum << i
      i += increment_value
    end
    options_for_select(enum)
  end
end
