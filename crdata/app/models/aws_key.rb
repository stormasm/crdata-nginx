class AwsKey < ActiveRecord::Base
  belongs_to :user
  has_many   :processing_nodes
  
  before_save :aws_encrypt 
  
  def aws_encrypt
    ez_key    = EzCrypto::Key.with_password AWS_PWD, AWS_SALT, :algorithm=>"aes256"
    self.access_key_id  = ez_key.encrypt64( self.access_key_id )
    self.secret_access_key = ez_key.encrypt64( self.secret_access_key )
  end
 
  def aws_decrypt
    ez_key     = EzCrypto::Key.with_password AWS_PWD, AWS_SALT, :algorithm=>"aes256"
    [ ez_key.decrypt64(self.access_key_id), ez_key.decrypt64(self.secret_access_key) ]
  end   
  
  def self.is_crdata_key?(key)
    return(AWS_ACCESS_KEY == key)
  end  
end
