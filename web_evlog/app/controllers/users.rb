# encoding: utf-8
WebEvlog.controllers :users do

  # routingとcontrollerが一体になってる
  post :create, map: "/users/create" do
    _params = params.dup.select{|k| ["email", "password"].include?(k)}
    @user = User.new(_params)
    if @user.save
      flash[:notice] = "user created"
      redirect '/users/login'
    else
      flash[:notice] = "user didn't saved"
      redirect '/users/signup'
    end
  end

  get :signup, map: '/users/signup' do
    render :haml, <<-__EOL__
= form_for User.new, '/users/create', method: :post do
  = text_field_tag :email, required: true
  = password_field_tag :password, required: true
  = submit_tag "Create"
    __EOL__
  end


  get :login, map: '/users/login' do
    binding.pry
    render :haml, <<-__EOL__
= flash[:notice] if flash[:notice] != nil
= form_tag '/sessions/new' do
  = text_field_tag :email, required: true
  = password_field_tag :password, required: true
  = submit_tag "login"
    __EOL__
  end

  get :logout, map: '/users/logout' do
  end

  # get :sample, :map => "/sample/url", :provides => [:any, :js] do
  #   case content_type
  #     when :js then ...
  #     else ...
  # end

  # get :foo, :with => :id do
  #   "Maps to url '/foo/#{params[:id]}'"
  # end

  # get "/example" do
  #   "Hello world!"
  # end

end
