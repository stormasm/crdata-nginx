class Group < ActiveRecord::Base
  acts_as_tsearch :fields => ['name']

  has_many :group_users, :dependent => :destroy
  has_many :users, :through => :group_users
  has_many :accesses, :dependent => :destroy

  validates_presence_of   :name
  validates_uniqueness_of :name

  named_scope :invited,  :conditions => "status = 'invited'"
  named_scope :approved, :conditions => "status = 'approved'"
  named_scope :default,  :conditions => "is_default IS TRUE"

  def self.get_groups(user, criteria)
    if !criteria[:search].blank?
      records = find_by_tsearch(criteria[:search], :conditions => 'is_default IS FALSE', :order => get_sort_criteria(criteria[:sort]))
      records = records.paginate(:page => criteria[:page], :per_page => ITEMS_PER_PAGE) unless criteria[:show] 
    elsif criteria[:my_groups]
      records = (criteria[:show]) ? user.groups(:conditions => 'is_default IS FALSE', :order => get_sort_criteria(criteria[:sort])) : user.groups.paginate(:conditions => 'is_default IS FALSE', :order => get_sort_criteria(criteria[:sort]), :page => criteria[:page], :per_page => ITEMS_PER_PAGE)  
    else
      records = (criteria[:show]) ? all(:conditions => 'is_default IS FALSE', :order => get_sort_criteria(criteria[:sort])) : paginate(:conditions => 'is_default IS FALSE', :order => get_sort_criteria(criteria[:sort]), :page => criteria[:page], :per_page => ITEMS_PER_PAGE)  
    end
    records
  end

  def r_scripts
    RScript.all(:select => 'DISTINCT(r_scripts.*)', 
      :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id',
      :conditions => ['accesses.accessable_type = \'RScript\' AND accesses.group_id = ?', self.id])
  end

  def data_sets
    DataSet.all(:select => 'DISTINCT(data_sets.*)', 
      :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id',
      :conditions => ['accesses.accessable_type = \'DataSet\' AND accesses.group_id = ?', self.id])
  end

  def jobs_queues
    JobsQueue.all(:select => 'DISTINCT(jobs_queues.*)', 
      :joins => 'LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id',
      :conditions => ['accesses.accessable_type = \'JobsQueue\' AND accesses.group_id = ?', self.id])
  end

 private

  # Get the sort criteria for groups
  def self.get_sort_criteria(sort)
    case sort
    when 'id'                   then 'id'
    when 'name'                 then 'name'
    when 'description'          then 'description'
    when 'id_reverse'           then 'id DESC'
    when 'name_reverse'         then 'name DESC'
    when 'description_reverse'  then 'description DESC'
    else 'updated_at DESC'
    end
  end
 
end
