# coding: utf-8

$:.unshift(File.expand_path("../lib", __FILE__))

require "bundler/setup"
require "pure_sender"
require "logging"
require "sinatra"

configure do
  # logging is enabled by default in classic style applications,
  # so `enable :logging` is not needed
  file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  file.sync = true
  use Rack::CommonLogger, file
end

run PureSender::Application
