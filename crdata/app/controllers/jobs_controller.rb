class JobsController < ApplicationController
  require 'chronic_duration'

  before_filter :require_user,      :except => [:index, :new, :create, :show, :submit, :do_submit, :run, :done, :clone, :cancel, :uploadurls]
  before_filter :require_job_owner, :except => [:index, :new, :create, :destroy_all, :run, :done, :uploadurls, :send_feedback]
 
  # GET /jobs
  # GET /jobs.xml
  def index
    respond_to do |format|
      format.html 
      format.js   { render :partial => 'list', :locals => { :jobs => Job.get_jobs(current_user, params) } }
      format.xml  { render :xml => Job.get_jobs(current_user, params.merge({:show => 'all'})) }
    end
  end

  # GET /jobs/1
  # GET /jobs/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @job.to_xml(:include => { :job_parameters => { :include => :data_set } }) }
    end
  end

  # GET /jobs/new
  # GET /jobs/new.xml
  def new
    @job = Job.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @job }
    end
  end

  # GET /jobs/1/edit
  def edit
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @job }
    end
  end

  # POST /jobs
  # POST /jobs.xml
  def create
    @job = Job.new(params[:job])
    @job.user = current_user

    respond_to do |format|
      if @job.save
        flash[:notice] = 'Job was successfully created.'
        format.html { redirect_to(jobs_url) }
        format.xml  { render :xml => @job.to_xml(:include => { :job_parameters => { :include => :data_set } }), :status => :created, :location => @job }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1
  # PUT /jobs/1.xml
  def update
    respond_to do |format|
      if @job.update_attributes(params[:job])
        flash[:notice] = 'Job was successfully updated.'
        format.html { redirect_to(@job) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /jobs/1
  # DELETE /jobs/1.xml
  def destroy
    respond_to do |format|
      if result = @job.destroy_job === true 
        flash[:notice] = 'Job was deleted.'
      format.html { redirect_to(jobs_url) }
      format.xml  { head :ok }
      else
        flash[:notice] = result
        format.html { redirect_to(jobs_url) }
        format.xml  { render :xml => result, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /jobs/destroy_all
  # DELETE /jobs/destroy_all.xml
  def destroy_all
    params[:job_ids].each do |job_id|
      job = Job.find(job_id)
      job.destroy if job.user == current_user
    end unless params[:job_ids].blank?
 
    respond_to do |format|
      format.html { redirect_to(jobs_url(:statuses => params[:statuses], :show => params[:show], :sort => params[:sort])) }
      format.xml  { head :ok }
    end
  end

  # GET /jobs/1/submit
  def submit
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @job }
    end
  end

  # PUT /jobs/1/do_submit
  # PUT /jobs/1/do_submit.xml
  def do_submit
    @job = Job.find(params[:id])
    @queue = JobsQueue.find_by_id(params[:job][:jobs_queue_id]) || JobsQueue.default_queue
    respond_to do |format|
      if @job.submit(@queue)
        flash[:notice] = 'Job was successfully submitted.'
        format.html { redirect_to(@job) }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1/run
  # PUT /jobs/1/run.xml
  def run
    @job = Job.find(params[:id])
    @processing_node = ProcessingNode.find_by_ip_address(request.remote_ip) || ProcessingNode.find(params[:node])

    respond_to do |format|
      if @job.run(@processing_node)
        flash[:notice] = 'Job was successfully started.'
        format.html { redirect_to(@job.r_script) }
        format.xml  { render :xml => @job.r_script }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1/done
  # PUT /jobs/1/done.xml
  def done
    @job = Job.find(params[:id])

    respond_to do |format|
      if @job.done(params[:success] || params[:success] == 'true')
        flash[:notice] = @job.successful ? 'Job was successfully finished.' : 'Job was finished with errors.'
        Notifier.deliver_notify_user_of_job_completion(@job)  
        format.html { redirect_to(@job) }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1/clone
  # PUT /jobs/1/clone.xml
  def clone
    @job = Job.find(params[:id]).cloned_job
  
    respond_to do |format|
      if @job.valid?
     #   flash[:notice] = 'Job was successfully cloned.'
        format.html { render :action => "new" }
        format.xml  { 
                    if @job.save!
                      @job.submit() 
                      head :ok
                    else
                       render :xml => @job.errors, :status => :unprocessable_entity
                    end      
                    }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1/cancel
  # PUT /jobs/1/cancel.xml
  def cancel
    @job = Job.find(params[:id])

    respond_to do |format|
      if @job.cancel 
        flash[:notice] = 'Job was successfully cancelled.'
        format.html { redirect_to(@job) }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /jobs/1/uploadurls
  # GET /jobs/1/uploadurls.xml
  def uploadurls
    @job = Job.find(params[:id])
    respond_to do |format|
      @url_list = @job.uploadurls(params[:upload_type], params[:files])
      if !@url_list.blank?
        format.html 
        format.xml  { render :xml => { :files => @url_list } }
      else
        @job.errors.add_to_base('Bad files list')
        format.html { render :action => "show" }
        format.xml  { render :xml => { 'error' => 'bad files list'}, :status => :unprocessable_entity }
      end
    end
  end

  # POST /jobs/send_feedback
  def send_feedback
    @job = Job.find(params[:job_id])
    Notifier.deliver_feedback_notification(@job, current_user, params[:message])

    respond_to do |format|
      format.js
    end
  end

 
  private

  def require_job_owner
    @job = Job.find(params[:id])

    unless current_user == @job.user
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to account_url
      return false
    end
  end
end
