# coding: utf-8

$:.unshift(File.expand_path("../lib", __FILE__))

require "bundler/setup"
require "file_sender"

#begin
#  require "rspec/core/rake_task"
#
#  desc "Run all specs"
#  RSpec::Core::RakeTask.new(:spec) do |t|
#    t.rspec_opts = ["-fs", "-c"]
#  end
#rescue LoadError
#  # If without development test at bundle install
#  task :default => :setup
#else
#  task :default => :spec
#end

CONFIG = PureSender::Application.configuration

directory CONFIG["filepath"]

desc "Create all database"
task :createdb do
  Tables.all_create
end

desc "Setup PureSender"
task :setup => [CONFIG["filepath"], :createdb] do
  user = PureSender::User.new
  user.username = CONFIG["root"]
  user.salt = Passwd.hashing(Time.now.to_s)
  user.password = Passwd.hashing("#{user.salt}#{CONFIG["password"]}")
  user.role = 0
  user.save
end

desc "Deleted files cleanup"
task :clean do
  files = Dir.glob(File.join(PureSender::Application.root, CONFIG["filepath"], "**", "*"))
  files.each do |file|
    if PureSender::RegisterFile.where("path = ?", file).count == 0
      File.unlink file
    end
  end
end

