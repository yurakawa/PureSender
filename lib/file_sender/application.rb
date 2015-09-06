# coding: utf-8

require "file_sender/helpers"

module PureSender
  VERSION = "0.2.0"
  
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    address:   'smtp.gmail.com',
    port:      587,
    domain:    'smtp.gmail.com',
    enable_starttls_auto: false,
    user_name: 'example@gmail.com',
    password: 'password'
    #authentication: :plain
  }

  class Mail < ActionMailer::Base
    def createMassage(toAddress, ccAddress, bccAddress, fromAddress, subject, body, file_path, file_name)
      attachments[file_name] = File.read(file_path)
      mail(
        :to => toAddress,
        :cc => ccAddress,
        :bcc => bccAddress,
        :from => fromAddress,
        :subject => subject,
        :body => body.to_s,
      )
    end
  end


  class Application < Sinatra::Base
    configure do
      # Application root directory
      set :root, File.expand_path("../../..", __FILE__)

      # Session configration
      # Specify the secret to share session in multiple instances and restart the application.
      set :sessions, true
      # set :session_secret, "super secret"

      # Application configration
      set :configuration, YAML.load_file(File.expand_path("../../../config/configuration.yml", __FILE__))
      set :database, YAML.load_file(File.expand_path("../../../config/database.yml", __FILE__))
    end

    before do
      exclude_path = ["/login", "/logout"]
      unless exclude_path.include? request.path_info
        if session[:user]
          begin
            @current = User.find(session[:user])
          rescue ActiveRecord::RecordNotFound
            session.clear
            halt 404
          end
        end

        redirect "/login" unless @current
        @categories = Category.order("name")
      end
    end

    after do
      ActiveRecord::Base.connection.close
    end

    helpers do
      include Helpers
    end

    get "/login" do
      erb :login, layout: false
    end

    post "/login" do
      user = User.authenticate(params[:username], params[:password])
      if user.nil?
        @alert = "username or password is incorrect."
        erb :login, layout: false
      else
        session[:user] = user.id
        session[:notice] = "Logged in successfully."
        redirect root_path
      end
    end

    get "/logout" do
      session.clear
      redirect "/login"
    end

    post "/change_password" do
      if params[:new_password].size > 0
        if @current.update_password(params[:old_password], params[:new_password])
          @current.save
          session[:notice] = "Password changed successfully."
        else
          session[:alert] = "Old password is incorrect."
        end
      else
        session[:alert] = "Password least one of the characters"
      end
      redirect root_path
    end

    get "/" do
      get_message
      @users = User.order(:role, :username) if @current.root?
      erb :index
    end

    get "/categories/:id" do
      get_message
      begin
        @category = Category.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        halt 404
      end
      begin
        tempfiles =  Dir.entries("#{settings.root}/#{settings.configuration["filepath"]}/#{@category.name}").delete_if{|x| /^\./ =~ x}
        tempfiles.each do |fname|
          @file = RegisterFile.new
          @file.name = fname
          @file.ftype = MIME::Types.type_for("#{settings.root}/#{settings.configuration["filepath"]}/#{@category.name}/#{fname}")[0].to_s
          @file.path = "#{settings.root}/#{settings.configuration["filepath"]}/#{@category.name}/#{fname}"
          @file.category = @category
          @file.save
        end
      rescue
#        halt 500
      end
      @files = @category.register_files.order("register_files.name")
      erb :category
    end

    get "/categories/:category_id/files/:id/mail" do
      #get_message
      begin
        @file = RegisterFile.find(params[:id])
        @template = MailTemplate.find_by_category_id(params[:category_id]) || @template = MailTemplate.new
        @category = Category.find(params[:category_id])
      rescue
        halt 500
      end
      tor = get_term(@file.name)
      @template.subject = insert_tor(@template.subject, tor)
      @template.body = insert_tor(@template.body, tor)
      erb :mail
    end


    get "/categories/:id/template" do
      #get message
      begin
        @category = Category.find(params[:id])
        @template = MailTemplate.find(params[:id])
      rescue
        halt 500
      end
      erb :template
    end

    post "/add_template" do
      begin
        @category = Category.find(params[:category_id])
      rescue
         halt 500
      end
      @template = MailTemplate.find_by_category_id(params[:category_id]) || @template = MailTemplate.new
      @template.from     = params[:from]      
      @template.to       = params[:to]        
      @template.cc       = params[:cc]        
      @template.bcc      = params[:bcc]       
      @template.subject  = params[:subject]   
      @template.body     = params[:body]
      @template.category_id = params[:category_id].to_i

      if @template.save
        session[:notice] = "MailTemplate registed successfully."
      else
        session[:alert] = @template.errors.messages.first.flatten.join(": ")
      end
      redirect root_path
    end

    get "/files/:id" do
      begin
        @file = RegisterFile.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        halt 404
      end
      content_type @file.ftype
      attachment @file.name
      read_registerfile @file.path
    end

    # for Administrator
    post "/add_category" do
      require_root!
      @category = Category.new(params[:category])
      if @category.save
        Dir.mkdir("#{settings.root}/#{settings.configuration['filepath']}/#{params[:category][:name]}")
        # add file of mail's body
        File.open("#{settings.root}/#{settings.configuration['filepath']}/#{params[:category][:name]}.txt", "w").close()
        session[:notice] = "Category created successfully."
      else
        session[:alert] = @category.errors.messages.first.flatten.join(": ")
      end
      redirect root_path
    end

    post "/del_category" do
      require_root!
      begin
        @category = Category.find(params[:category_id])
      rescue ActiveRecord::RecordNotFound
        halt 404
      end
      @category.destroy
      session[:notice] = "Category deleted successfully."
      redirect root_path
    end

    post "/add_file" do
      require_root!
      begin
        @category = Category.find(params[:category_id])
      rescue ActiveRecord::RecordNotFound
        halt 404
      end

      begin
        @file = RegisterFile.new
        @file.name = params[:file][:filename]
        @file.ftype = params[:file][:type]
        #todo
        @file.path = "#{settings.root}/#{settings.configuration["filepath"]}/#{@category.name}/#{params[:file][:filename]}"
        @file.category = @category
        write_registerfile @file.path, params[:file][:tempfile].read
      rescue
        #        halt 500
      end

      if @file.save
        session[:notice] = "File registered successfully."
      else
        session[:alert] = @file.errors.messages.first.flatten.join(": ")
      end
      redirect category_path(@category)
    end

    post "/del_file" do
      require_root!
      begin  
        @category = Category.find(params[:category_id])
        @file = RegisterFile.find(params[:file_id])
      rescue
        halt 404
      end
      begin
        File.unlink(@file.path)
        @file.destroy
      rescue
        #session[:notice] = "No such file or directory."
        session[:notice] = @file.path
        redirect category_path(@category)
      end
      session[:notice] = "File deleted successfully."
      redirect category_path(@category)
    end

    post "/send_mail" do
      begin
        @category = Category.find(params[:category_id])
      rescue
      end
      file_path = params[:file_path]
      file_name = params[:file_name]
      to = params[:to]
      cc = params[:cc]
      bcc = params[:bcc]
      from = params[:from]
      subject = params[:subject]
      body = params[:body]
      Mail.createMassage(to, cc, bcc, from, subject, body, file_path, file_name).deliver
      session[:notice] = "Mail Sended successfully."
      redirect category_path(@category)
    end


    post "/add_user" do
      require_root!
      @user = User.new
      @user.username = params[:username]
      @user.salt = Passwd.hashing("#{params[:username]}#{Time.now.to_s}")
      @user.password = Passwd.hashing("#{@user.salt}#{params[:password]}")
      @user.role = 0 if params[:role] == "admin"
      if @user.save
        session[:notice] = "User registered successfully."
      else
        session[:alert] = @user.errors.messages.first.flatten.join(": ")
      end
      redirect root_path
    end

    post "/del_user" do
      require_root!
      begin
        @user = User.find(params[:user_id])
      rescue ActiveRecord::RecordNotFound
        halt 404
      end

      if @user != @current && @user.username != settings.configuration["root"]
        @user.destroy
        session[:notice] = "User deleted successfully."
        redirect root_path
      else
        halt 500
      end
    end

    not_found do
      "Not found"
    end

    error 500 do
      "Server internal error"
    end
  end
end
