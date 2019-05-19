class JobsQueue < ActiveRecord::Base
  has_many :processing_nodes
  has_many :jobs, :order => :submitted_at
  has_many :accesses, :as => :accessable

  acts_as_tsearch :fields => ['name']

  validates_uniqueness_of :name, :case_sensitive => false 
  validates_presence_of :name
  
  def self.get_jobs_queues(user, criteria)
    if !criteria[:search].blank?
      records = find_by_tsearch(criteria[:search], 
        :select => 'DISTINCT(jobs_queues.*)', 
        :joins => 'LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['(jobs_queues.is_public IS TRUE OR (accesses.accessable_type = \'JobsQueue\' AND group_users.user_id = ?))', user], 
        :order => get_sort_criteria(criteria[:sort]))
      records = records.paginate(:page => criteria[:page], :per_page => ITEMS_PER_PAGE) unless criteria[:show] 
    else
      if criteria[:show]
        records = all(:select => 'DISTINCT(jobs_queues.*)', 
          :joins => 'LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
          :conditions => ['(jobs_queues.is_public IS TRUE OR (accesses.accessable_type = \'JobsQueue\' AND group_users.user_id = ?))', user], 
          :order => get_sort_criteria(criteria[:sort]))
      else
        records = paginate(:select => 'DISTINCT(jobs_queues.*)', 
          :joins => 'LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
          :conditions => ['(jobs_queues.is_public IS TRUE OR (accesses.accessable_type = \'JobsQueue\' AND group_users.user_id = ?))', user], 
          :order => get_sort_criteria(criteria[:sort]), 
          :page => criteria[:page], 
          :per_page => ITEMS_PER_PAGE)  
      end
    end
    records
  end
 
  def self.public_jobs_queues
    all(:conditions => 'is_public IS TRUE')
  end

  # The default queue to use (usually the public one)
  # In the initial phase it's the only one we have - or the first one
  def self.default_queue
    self.first :order => :id
  end

  # Return the job position in the queue 0 based
  # return nil if the job isn't in the queue
  def job_position(job)
    jobs.index(job)
  end

  # Get the next scheduled job and return it. nil if none available or error
  def run_next_job(proc_node)
    job = nil
    get_next_job = true
    self.transaction do
      while get_next_job
        begin
          job = jobs.first
          job.run(proc_node) if job
          get_next_job = false
        rescue => ex
          # Just name sure we go on
          logger.info "Exception getting next job from queue: #{ex}"
        end
      end
    end
    job
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
    User.first(:select => 'DISTINCT(users.*)', 
      :joins => 'LEFT JOIN group_users ON users.id = group_users.user_id LEFT JOIN accesses ON accesses.group_id = group_users.group_id', 
      :conditions => ['accesses.accessable_type = \'JobsQueue\' AND group_users.role_id = ? AND accesses.accessable_id = ?', Role.find_by_name('Owner').id, self.id])
  end

  private

  # Get the sort criteria for jobs queues
  def self.get_sort_criteria(sort)
    case sort
    when 'id'                   then 'id'
    when 'name'                 then 'name'
    when 'id_reverse'           then 'id DESC'
    when 'name_reverse'         then 'name DESC'
    else 'name'
    end
  end

end
