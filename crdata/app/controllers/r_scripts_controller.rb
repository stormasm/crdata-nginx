class RScriptsController < ApplicationController
  uses_tiny_mce :options => { :theme => 'advanced', 
    :width => 720,
    :theme_advanced_toolbar_location => 'top',
    :theme_advanced_buttons1 => 'bold,italic,strikethrough,bullist,numlist, separator,undo,redo,separator,link,unlink,image, separator,cleanup,code,removeformat,charmap, fullscreen,paste',
    :theme_advanced_buttons2 =>  '',
    :theme_advanced_buttons3 =>  '',
    :save_callback => 'setDescription'
  }

  before_filter :require_user,            :except => [:index, :get_data_form, :help_page]
  before_filter :require_r_script_owner,  :only =>   [:edit, :update, :destroy]
  before_filter :require_r_script_access, :only =>   [:show]

  # GET /r_scripts
  # GET /r_scripts.xml
  def index
    @tags = RScript.tag_counts(:joins => 'LEFT JOIN accesses ON r_scripts.id = accesses.accessable_id LEFT JOIN group_users on accesses.group_id = group_users.group_id', 
      :conditions => ['(r_scripts.is_public IS TRUE OR (accesses.accessable_type = \'RScript\' AND group_users.user_id = ?))', current_user]) 
    respond_to do |format|
      format.html { @r_scripts = RScript.get_r_scripts(current_user, params) }
      format.xml  { render :xml => RScript.get_r_scripts(current_user, params.merge({:show => 'all'})) }
    end
  end

  # GET /r_scripts/1
  # GET /r_scripts/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @r_script.to_xml(:include => :parameters) }
    end
  end

  # GET /r_scripts/new
  # GET /r_scripts/new.xml
  def new
    @r_script = RScript.new
    session[:parameters] = nil

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @r_script }
    end
  end

  # GET /r_scripts/1/edit
  def edit
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @r_script }
    end
  end

  # POST /r_scripts
  # POST /r_scripts.xml
  def create
    @r_script = RScript.new(params[:r_script])
    @r_script.source_code = params[:r_script][:file].read unless params[:r_script][:file].blank?

    respond_to do |format|
      if @r_script.save
        if session[:parameters]
          @r_script.link_parameters(session[:parameters]) 
          session[:parameters] = nil
        end
        @r_script.set_visibility(current_user, params)
        flash[:notice] = 'RScript was successfully created.'
        format.html { redirect_to(@r_script) }
        format.xml  { render :xml => @r_script.to_xml(:include => :parameters), :status => :created, :location => @r_script }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @r_script.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /r_scripts/1
  # PUT /r_scripts/1.xml
  def update
    params[:r_script][:source_code] = params[:r_script][:file].read unless params[:r_script][:file].blank?
  
    respond_to do |format|
      if @r_script.update_attributes(params[:r_script])
        if session[:parameters]
          @r_script.link_parameters(session[:parameters]) 
          session[:parameters] = nil
        end
        @r_script.set_visibility(current_user, params)
        flash[:notice] = 'RScript was successfully updated.'
        format.html { redirect_to(@r_script) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @r_script.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /r_scripts/1
  # DELETE /r_scripts/1.xml
  def destroy
    @r_script.destroy

    respond_to do |format|
      format.html { redirect_to(r_scripts_url) }
      format.xml  { head :ok }
    end
  end

  # DELETE /r_scripts/destroy_all
  # DELETE /r_scripts/destroy_all.xml
  def destroy_all
    params[:r_script_ids].each do |r_script_id|
      r_script = RScript.find(r_script_id)
      r_script.destroy if current_user.groups.default.first.r_scripts.include?(r_script)
    end unless params[:r_script_ids].blank?
 
    respond_to do |format|
      format.html { redirect_to(r_scripts_url(:show => params[:show], :sort => params[:sort], :search => params[:search], :tag => params[:tag])) }
      format.xml  { head :ok }
    end
  end

  # POST /r_scripts/get_data_form
  def get_data_form 
    @r_script = RScript.find(params[:id])

    respond_to do |format|
      format.js 
    end
  end

  # GET /r_scripts/help_page
  def help_page 
    @r_script = RScript.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  private

  def require_r_script_owner
    @r_script = RScript.find(params[:id])

    unless current_user.groups.default.first.r_scripts.include?(@r_script)
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to account_url
      return false
    end
  end
 
  def require_r_script_access
    @r_script = RScript.find(params[:id])

    unless @r_script.is_public or current_user.r_scripts.include?(@r_script)
      store_location
      flash[:notice] = 'You don\'t have permission to access this page'
      redirect_to account_url
      return false
    end
  end

end
