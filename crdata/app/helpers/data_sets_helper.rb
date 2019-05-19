module DataSetsHelper

  # Get dataset actions  
  def get_data_set_actions(record)
    if current_user and current_user.groups.default.first.data_sets.include?(record)
      link_to('Edit', edit_data_set_path(record)) + 
      link_to('Destroy', record, :confirm => 'Are you sure you want to delete this dataset?', :method => :delete)
    end
  end

  
end
