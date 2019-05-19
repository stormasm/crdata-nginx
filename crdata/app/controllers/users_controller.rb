class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]
           
  def show
    @user = @current_user
 
    respond_to do |format|
      format.html
    end
  end
     
  def new
    @user = User.new
 
    respond_to do |format|
      format.html
    end
  end
        
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save_without_session_maintenance
        @user.deliver_activation_instructions!
        flash[:notice] = "Your account has been created. Please check your e-mail for your account activation instructions!"
        format.html { redirect_back_or_default root_url }
      else
        format.html { render :action => :new }
      end
    end
  end
           
  def edit
    @user = @current_user
  
    respond_to do |format|
      format.html
    end
  end
              
  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = "Account updated!"
        format.html { redirect_to account_url }
      else
        format.html { render :action => :edit }
      end
    end
  end
end
