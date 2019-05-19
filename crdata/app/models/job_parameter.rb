class JobParameter < ActiveRecord::Base
  belongs_to :job
  belongs_to :parameter
  belongs_to :data_set

  before_save {|record| record.value.strip! if %w(Integer Float Enumeration Boolean List).include?(record.parameter.kind)} 

  def data_set_url
    if data_set
      s3 = RightAws::S3Interface.new(AWS_ACCESS_KEY, AWS_SECRET_KEY)
      s3.get_link(data_set.bucket, data_set.file_name, 60*60*24)
    else
       nil
    end
  end

  def to_xml(*args)
    super do |xml|
      xml.data_set_url data_set_url
      xml.name parameter.name
      xml.kind parameter.kind
    end
  end

end
