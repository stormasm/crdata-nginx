ActionController::Routing::Routes.draw do |map|
  # Specialized routes for job management - must be before the default rails REST ones to avoid conflicts
  map.run_job               'jobs/:id/run/:node.:format', :controller => 'jobs', :action => :run, :conditions => { :method => :put }
  map.done_job              'jobs/:id/done.:format', :controller => 'jobs', :action => :done, :conditions => { :method => :put }
  map.clone_job             'jobs/:id/clone.:format', :controller => 'jobs', :action => :clone, :conditions => { :method => :put }
  map.cancel_job            'jobs/:id/cancel.:format', :controller => 'jobs', :action => :cancel, :conditions => { :method => :put }
  map.uploadurls_job        'jobs/:id/uploadurls.:format', :controller => 'jobs', :action => :uploadurls, :conditions => { :method => :get }
  map.run_next_job_default  'jobs_queues/run_next_job.:format', :controller => 'jobs_queues', :action => 'run_next_job', :conditions => { :method => :put }
  map.run_next_job_on_node  'jobs_queues/run_next_job/:node.:format', :controller => 'jobs_queues', :action => 'run_next_job', :conditions => { :method => :put }
  map.run_next_job_in_queue 'jobs_queues/:id/run_next_job.:format', :controller => 'jobs_queues', :action => 'run_next_job', :conditions => { :method => :put }
  map.run_next_job          'jobs_queues/:id/run_next_job/:node.:format', :controller => 'jobs_queues', :action => 'run_next_job', :conditions => { :method => :put }
  map.register              'register/:activation_code', :controller => 'activations', :action => 'new'
  map.activate              'activate/:id', :controller => 'activations', :action => 'create'

  map.resource  :user_session
  map.resource  :account, :controller => 'users'
  
  map.resources :users
  map.resources :job_data_sets
  map.resources :processing_nodes, :collection => {:destroy_all => :delete, :register => :get, :unregister => :get}, :member => {:manage_donation => :get, :do_manage_donation => :put}
  map.resources :jobs, :collection => {:send_feedback => :post, :destroy_all => :delete}, :member => {:submit => :get, :do_submit => :put, :uploadurls => :get}
  map.resources :r_script_logs
  map.resources :r_script_results
  map.resources :data_sets, :collection => {:destroy_all => :delete}
  map.resources :r_scripts, :collection => {:get_data_form => :post, :destroy_all => :delete}, :member => {:help_page => :get}
  map.resources :jobs_queues, :has_many => [:jobs], :collection => {:destroy_all => :delete}
  map.resources :parameters
  map.resources :password_resets
  map.resources :groups, :member => {:join => :get}
  map.resources :group_users, :member => {:approve => :get, :reject => :get, :remove => :get, :leave => :get, :accept => :get, :decline => :get, :cancel_invite => :get, :change_role => :get}

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
   map.root :controller => "static", :action => "index"
   map.tour '/tour', :controller => "static", :action => "tour"
   map.privacy '/privacy', :controller => "static", :action => "privacy"
   map.about '/about', :controller => "static", :action => "about"
   map.help '/help', :controller => "static", :action => "help"
   map.guest '/guest', :controller => "static", :action => "guest"
   map.new_job '/jobs/new', :controller => "jobs", :action => "new"
   map.data '/data', :controller => "data", :action => "index"
   map.new_data '/data/new', :controller => "data", :action => "new"
   map.edit_data '/data/edit', :controller => "data", :action => "edit"
   map.scripts '/scripts', :controller => "scripts", :action => "index"
   map.new_script '/scripts/new', :controller => "scripts", :action => "new"
   map.edit_script '/scripts/edit', :controller => "scripts", :action => "edit"
   
   map.my_account '/my_account', :controller => "users", :action => "edit"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
end
