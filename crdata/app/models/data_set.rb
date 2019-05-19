class DataSet < ActiveRecord::Base
  acts_as_taggable
  acts_as_tsearch :fields => ['name']
  
  has_many :job_parameters, :dependent => :destroy
  has_many :jobs, :through => :job_parameters
  has_many :accesses, :as => :accessable

  validates_uniqueness_of :name, :case_sensitive => false
  validates_presence_of   :name 

  def self.get_data_sets(user, criteria)
    if !criteria[:search].blank?
      records = find_by_tsearch(criteria[:search], 
        :select => 'DISTINCT(data_sets.*)', 
        :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['(data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?))', user], 
        :order => get_sort_criteria(criteria[:sort]))
      records = records.paginate(:page => criteria[:page], :per_page => ITEMS_PER_PAGE) unless criteria[:show] 
    elsif criteria[:tag]
      records = find_tagged_with(criteria[:tag], 
        :select => 'DISTINCT(data_sets.*)', 
        :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?)', user], 
        :order => get_sort_criteria(criteria[:sort]))
      records = paginate_tagged_with(criteria[:tag], 
        :select => 'DISTINCT(data_sets.*)', 
        :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
        :conditions => ['data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?)', user], 
        :order => get_sort_criteria(criteria[:sort]), 
        :page => criteria[:page], 
        :per_page => ITEMS_PER_PAGE, 
        :total_entries => records.size
      ) unless criteria[:show]
    else
      if criteria[:show]
        records = all(:select => 'DISTINCT(data_sets.*)', 
          :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
          :conditions => ['(data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?))', user], 
          :order => get_sort_criteria(criteria[:sort]))
      else
        records = paginate(:select => 'DISTINCT(data_sets.*)', 
          :joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
          :conditions => ['data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?)', user], 
          :order => get_sort_criteria(criteria[:sort]), 
          :page => criteria[:page], 
          :per_page => ITEMS_PER_PAGE)  
      end
    end
    records
  end
 
  def self.public_data_sets
    all(:conditions => 'is_public IS TRUE')
  end

  def save_and_upload_file(parameters)
    s3_credentials = (parameters[:visibility] != 'public') ? parameters['s3_credentials'] : {'access_key_id' => AWS_ACCESS_KEY, 'secret_access_key' => AWS_SECRET_KEY, 'bucket' => MAIN_BUCKET} 

    begin 
      AWS::S3::Base.establish_connection!(:access_key_id => s3_credentials['access_key_id'], :secret_access_key => s3_credentials['secret_access_key'])
      raise 'File could not be stored. Please try again' unless AWS::S3::S3Object.store("data/#{uuid = UUID.generate}/#{parameters['Filename']}", parameters['Filedata'], s3_credentials['bucket'], :access => (parameters['visibility'] == 'public') ? 'public_read' : 'private')
      self.file_name = "data/#{uuid}/#{parameters['Filename']}"
      self.bucket = s3_credentials['bucket']
      s3_object = AWS::S3::S3Object.find(file_name, bucket)
      policy = s3_object.acl
      grant = AWS::S3::ACL::Grant.new
      grantee = AWS::S3::ACL::Grantee.new
      grant.grantee = grantee
      grant.permission = 'READ'
      policy.grants << grant
      grantee.type = 'CanonicalUser'
      grantee.id = S3_OWNER_ID
      grantee.display_name = S3_OWNER_DISPLAY_NAME
      s3_object.acl(policy)
    rescue  Exception => e
      self.errors.add('bucket', e.message)
      return false
    else
      result = self.save
      s3_object.delete unless errors.empty?
    end
    result
  end
 
  def set_visibility(user, parameters)
    self.accesses.each{|access| access.destroy}
    if parameters['visibility'] == 'public'
      self.is_public = true
    else
      self.is_public = false
      parameters['groups'].delete("") if parameters['groups']
      parameters['groups'].each do |group_id|
        self.accesses << Access.new(:group_id => group_id)
      end unless parameters['groups'].blank?
    end
    self.accesses << Access.new(:group_id => user.groups.default.first.id) if user
    self.save
  end

  def url
    "http://#{bucket}.s3.amazonaws.com/#{file_name}"
  end

  private

  # Get the sort criteria for datasets
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
