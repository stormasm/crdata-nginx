class User < ActiveRecord::Base
  acts_as_authentic do |u|
    u.login_field = :email
    u.validate_login_field = false 
  end

  has_many :group_users, :dependent => :destroy
  has_many :groups, :through => :group_users, :order => 'updated_at DESC'
  has_many :jobs
  has_many :processing_nodes
  has_many :aws_keys

  before_create :downcase_email

  validates_presence_of :first_name, :last_name
  
  named_scope :approved,  :conditions => "status = 'approved'"
  named_scope :rejected,  :conditions => "status = 'rejected'"
  named_scope :requested, :conditions => "status = 'requested'"
  named_scope :invited,   :conditions => "status = 'invited'"
  named_scope :cancelled, :conditions => "status = 'cancelled'"
  named_scope :owners,    :conditions => ['group_users.role_id = ?', Role.find_by_name('Owner').id]
  named_scope :admins,    :conditions => ['group_users.role_id IN (?, ?)', Role.find_by_name('Owner').id, Role.find_by_name('Admin').id]
  named_scope :owners,    :conditions => ['group_users.role_id = ?', (Role.find_by_name('Owner').id rescue nil)]
  named_scope :admins,    :conditions => ['group_users.role_id IN (?, ?)', (Role.find_by_name('Owner').id rescue nil), (Role.find_by_name('Admin').id rescue nil)]

  def self.site_admins_emails
    find_all_by_is_admin(true).collect{|user| user.email}.join(', ')
  end

  def name
    "#{first_name} #{last_name}"
  end
  
  def active?
    is_active
  end

  def activate!
    self.is_active = true
    save
  end

  def is_site_admin?
    is_admin 
  end

  def deliver_activation_instructions!
    reset_perishable_token!
    Notifier.deliver_activation_instructions(self)
  end

  def deliver_activation_confirmation!
    reset_perishable_token!
    Notifier.deliver_activation_confirmation(self)
  end

  def deliver_password_reset_instructions!  
    reset_perishable_token!  
    Notifier.deliver_password_reset_instructions(self)  
  end

  def r_scripts
    RScript.all(:select => 'DISTINCT(r_scripts.*)', 
      :joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
      :conditions => ['(r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?))', self.id],
      :order => 'r_scripts.updated_at DESC')
  end

  def data_sets
    DataSet.all(:select => 'DISTINCT(data_sets.*)', 
      :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
      :conditions => ['(data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?))', self.id])
  end

  def jobs_queues
    JobsQueue.all(:select => 'DISTINCT(jobs_queues.*)', 
      :joins => 'LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
      :conditions => ['(jobs_queues.is_public IS TRUE OR (accesses.accessable_type = \'JobsQueue\' AND group_users.user_id = ?))', self.id])
  end

  def jobs_queues_admin
    jobs_queues = JobsQueue.all(:select => 'DISTINCT(jobs_queues.*)', 
      :joins => 'LEFT JOIN accesses ON jobs_queues.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
      :conditions => ['accesses.accessable_type = \'JobsQueue\' AND group_users.role_id IN (?, ?) AND group_users.user_id = ?', Role.find_by_name('Owner').id, Role.find_by_name('Admin').id, self.id])
    
    jobs_queues |= JobsQueue.public_jobs_queues if is_site_admin?
    jobs_queues
  end

  def jobs_queue_groups_admin(jobs_queue)
    Group.all(:select => 'DISTINCT(groups.*)', 
      :joins => 'LEFT JOIN accesses ON groups.id = accesses.group_id LEFT JOIN jobs_queues ON accesses.accessable_id = jobs_queues.id LEFT JOIN group_users ON groups.id = group_users.group_id', 
      :conditions => ['accesses.accessable_type = \'JobsQueue\' AND accessable_id = ? AND group_users.role_id IN (?, ?) AND group_users.user_id = ?', jobs_queue.id, Role.find_by_name('Owner').id, Role.find_by_name('Admin').id, self.id],
      :order => 'groups.updated_at DESC')
  end

 def is_group_owner?(group)
    !GroupUser.all(:conditions => ['user_id = ? AND group_id = ? AND role_id = ?', self.id, group.id, Role.find_by_name('Owner').id]).blank?
  end
  
  def is_group_admin?(group)
    !GroupUser.all(:conditions => ['user_id = ? AND group_id = ? AND role_id IN (?, ?)', self.id, group.id, Role.find_by_name('Owner').id, Role.find_by_name('Admin').id]).blank?
  end

  def is_group_member?(group)
    !GroupUser.all(:conditions => ['user_id = ? AND group_id = ? AND role_id = ?', self.id, group.id, Role.find_by_name('User').id]).blank?
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
