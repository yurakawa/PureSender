# coding: utf-8

module PureSender
  module Helpers
    include Rack::Utils
    alias_method :h, :escape_html

    def require_root!
      return if @current.root?
      halt 404
    end

    def get_message
      if session[:notice]
        @notice = session[:notice]
        session.delete(:notice)
      end

      if session[:alert]
        @alert = session[:alert]
        session.delete(:alert)
      end
    end

    # for get term of report
    # ex) args: 週間報告20140115-0121.zip
    #     return: 1/15-1/21
    def get_term(filename)
      dates = filename.scan(/(\d{4})-(\d{4})/)[0]
      date = dates.map!{|dts| dts.scan(/.{1,#{2}}/)}.map{|ss| ss.map!{|s| s.to_i}}
      date.map!{|dt| dt.join("/")}.join("-")
    rescue => e
      return "md1-md2"
    end

    def insert_tor(txt, tor)
      txt.gsub(/md1-md2/, tor)
    end

    def read_registerfile(path)
      File.open(path).read
    end

    def write_registerfile(path, content)
      File.open(path, "wb") do |f|
        f.write content
      end
    end

    # for redirects
    def root_path
      "/"
    end

    def category_path(category)
      "/categories/#{category.id}"
    end

    def file_path(file)
      "/files/#{file.id}"
    end

    # for views
    def p_role(user)
      user.root? ? "Administrator" : "User"
    end

    def p_filename_with_icon(file)
      case
      when file.ftype =~ /^image/ then icon = "icon-picture"
      else icon = "icon-file"
      end
      "<i class=\"#{icon}\"></i> #{h file.name}"
    end
  end
end
