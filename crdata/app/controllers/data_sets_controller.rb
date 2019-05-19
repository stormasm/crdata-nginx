class DataSetsController < ApplicationController
  before_filter :require_user,            :except => [:index, :new, :create, :show]
  before_filter :require_data_set_owner,  :only =>   [:edit, :update, :destroy]
  before_filter :require_data_set_access, :only =>   [:show]
  
  # GET /data_sets
  # GET /data_sets.xml
  def index
    @tags = DataSet.tag_counts(:joins => 'LEFT JOIN accesses ON data_sets.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
      :conditions => ['(data_sets.is_public IS TRUE OR (accesses.accessable_type = \'DataSet\' AND group_users.user_id = ?))', current_user]) 
    respond_to do |format|
      format.html { @data_sets = DataSet.get_data_sets(current_user, params) }
      format.xml  { render :xml => DataSet.get_data_sets(current_user, params.merge({:show => 'all'})) }
    end
  end

  # GET /data_sets/1
  # GET /data_sets/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @data_set }
    end
  end

  # GET /data_sets/new
  # GET /data_sets/new.xml
  def new
    @data_set = DataSet.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @data_set }
    end
  end

  # GET /data_sets/1/edit
  def edit
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @r_script }
    end
  end

  # POST /data_sets
  # POST /data_sets.xml
  def create
    @data_set = DataSet.new(params[:data_set])
    params[:visibility] = 'public' unless current_user

    respond_to do |format|
      if @success = @data_set.save_and_upload_file(params)
        @data_set.set_visibility(current_user, params)
        flash[:notice] = 'DataSet was successfully created.'
        format.all_text   
        format.html { redirect_to(@data_set) }
        format.xml  { render :xml => @data_set, :status => :created, :location => @data_set }
      else
        format.all_text   
        format.html { render :action => 'new' }
        format.xml  { render :xml => @data_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /data_sets/1
  # PUT /data_sets/1.xml
  def update
    respond_to do |format|
      if @data_set.update_attributes(params[:data_set])
        @data_set.set_visibility(current_user, params)
        flash[:notice] = 'DataSet was successfully updated.'
        format.html { redirect_to(@data_set) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @data_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /data_sets/1
  # DELETE /data_sets/1.xml
  def destroy
    @data_set.destroy

    respond_to do |format|
      format.html { redirect_to(data_sets_url) }
      format.xml  { head :ok }
    end
  end

  # DELETE /data_sets/destroy_all
  # DELETE /data_sets/destroy_all.xml
  def destroy_all
    params[:data_set_ids].each do |data_set_id|
      data_set = DataSet.find(data_set_id)
      data_set.destroy if current_user.groups.default.first.data_sets.include?(data_set)
    end unless params[:data_set_ids].blank?
 
    respond_to do |format|
      format.html { redirect_to(data_sets_url(:show => params[:show], :sort => params[:sort], :search => params[:search], :tag => params[:tag])) }
      format.xml  { head :ok }
    end
  end

  private

  def require_data_set_owner
    @data_set = DataSet.find(params[:id])

    unless current_user.groups.default.first.data_sets.include?(@data_set)
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to account_url
      return false
    end
  end
  
  def require_data_set_access
    @data_set = DataSet.find(params[:id])

    unless @data_set.is_public or (current_user and current_user.data_sets.include?(@data_set))
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to account_url
      return false
    end
  end

end
