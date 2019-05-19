# General settings required for the system to run

# Keys for the main CRData Amazon account - read from env!
AWS_ACCESS_KEY = ENV['CRDATA_ACCESS_KEY'] 
AWS_SECRET_KEY = ENV['CRDATA_SECRET_KEY'] 
MAIN_BUCKET    = 'crdataapp'
S3_URL = "http://#{MAIN_BUCKET}.s3.amazonaws.com"
SSL_S3_URL =  "https://#{MAIN_BUCKET}.s3.amazonaws.com"

# Number of items to show per page
ITEMS_PER_PAGE = 20

# Job statuses
JOB_STATUSES = %w(new submitted running done failed cancelled)

#HOSTNAME
CRDATA_HOST = "http://#{YAML.load_file(File.join(Rails.root, 'config', 'settings.yml'))['host']['hostname']}"
#R WORKER AMI
WORKER_IMG = YAML.load_file(File.join(Rails.root, 'config', 'settings.yml'))['host']['worker_image'] 

#AWS 
AWS_PWD = "http://#{YAML.load_file(File.join(Rails.root, 'config', 'settings.yml'))['aws']['password']}"
AWS_SALT = YAML.load_file(File.join(Rails.root, 'config', 'settings.yml'))['aws']['salt']

#EC2 Security Group Name
EC2_SECURITY_GROUP = 'r_node'
