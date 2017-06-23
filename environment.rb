require 'open-uri'
require 'cgi'
require 'nokogiri'
require 'sidekiq'
require 'sidekiq/api'
require 'time'
require 'mongo_mapper'
require 'json'
require 'pry'
Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/extensions/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/tasks/*.rb'].each {|file| require file }
CONFIG = JSON.parse(File.read("settings.json"))
MongoMapper.connection = Mongo::MongoClient.new(CONFIG["db_host"], 27017, :pool_size => 25, :op_timeout => 600000, :timeout => 600000, :pool_timeout => 600000)
MongoMapper.connection["admin"].authenticate(CONFIG["db_user"], CONFIG["db_password"])
MongoMapper.database = CONFIG["database"]

