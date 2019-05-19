class RScript < ActiveRecord::Base
  acts_as_taggable
  acts_as_tsearch :fields => ['name']

  attr_accessor :file

  has_many :jobs
  has_many :parameters, :dependent => :destroy
  has_many :accesses, :as => :accessable, :dependent => :destroy

  validates_uniqueness_of :name, :case_sensitive => false
  validates_presence_of   :name, :source_code

  def self.get_r_scripts(user, criteria)
    if !criteria[:search].blank?
      records = find_by_tsearch(criteria[:search], 
        :select => 'DISTINCT(r_scripts.*)', 
        :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['(r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?))', user], 
        :order => get_sort_criteria(criteria[:sort]))
      records = records.paginate(:page => criteria[:page], :per_page => ITEMS_PER_PAGE) unless criteria[:show] 
    elsif criteria[:tag]
      records = find_tagged_with(criteria[:tag], 
        :select => 'DISTINCT(r_scripts.*)', 
        :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?)', user], 
        :order => get_sort_criteria(criteria[:sort]))
      records = paginate_tagged_with(criteria[:tag], 
        :select => 'DISTINCT(r_scripts.*)', 
        :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?)', user], 
        :order => get_sort_criteria(criteria[:sort]), 
        :page => criteria[:page], 
        :per_page => ITEMS_PER_PAGE, 
        :total_entries => records.size
      ) unless criteria[:show]
    else
      if criteria[:show]
        records = all(:select => 'DISTINCT(r_scripts.*)', 
          :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
          :conditions => ['(r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?))', user], 
          :order => get_sort_criteria(criteria[:sort]))
      else
        records = paginate(:select => 'DISTINCT(r_scripts.*)', 
          :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
          :conditions => ['r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?)', user], 
          :order => get_sort_criteria(criteria[:sort]), 
          :page => criteria[:page], 
          :per_page => ITEMS_PER_PAGE)  
      end
    end
    records
  end
 
  def self.public_r_scripts
    all(:conditions => 'is_public IS TRUE', :order => 'r_scripts.updated_at DESC')
  end

  def link_parameters(parameters)
    parameters.each do |parameter_id|
      parameter = Parameter.find_by_id(parameter_id)
      self.parameters << parameter if parameter
    end
    self.save
  end

  def set_visibility(user, parameters)
    self.accesses.each{|access| access.destroy}
    if parameters[:visibility] == 'public'
      self.is_public = true
    else
      self.is_public = false
      parameters[:groups].each do |group_id|
        self.accesses << Access.new(:group_id => group_id)
      end unless parameters[:groups].blank?
    end
    self.accesses << Access.new(:group_id => user.groups.default.first.id)
    self.save
  end

  def owner
    User.first(:joins => 'LEFT JOIN group_users ON users.id = group_users.user_id LEFT JOIN groups ON group_users.group_id = groups.id LEFT JOIN accesses ON groups.id = accesses.group_id', 
               :conditions => ['groups.is_default IS TRUE AND accesses.accessable_id = ? AND accesses.accessable_type = \'RScript\'', id]
    )
  end

  private

  # Get the sort criteria for r_scripts
  def self.get_sort_criteria(sort)
    case sort
    when 'id'                   then 'id'
    when 'name'                 then 'name'
    when 'effort_level'         then 'effort_level'
    when 'id_reverse'           then 'id DESC'
    when 'name_reverse'         then 'name DESC'
    when 'effort_level_reverse' then 'effort_level DESC'
    else 'updated_at DESC'
    end
  end
end
