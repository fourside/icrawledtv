require 'rubygems'
require 'active_record'
require 'logger'
require 'yaml'
require 'uri'

if ENV['DATABASE_URL']
	db = URI.parse(ENV['DATABASE_URL'])
	ActiveRecord::Base.establish_connection(
		:adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
		:host     => db.host,
		:username => db.user,
		:password => db.password,
		:database => db.path[1..-1],
		:encoding => 'utf8',
		:min_messages => 'notice'
	)
else
	dbconfig = YAML.load_file(File.dirname(__FILE__) + '/config/database.yml')
	ActiveRecord::Base.establish_connection(dbconfig)
end
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/log/database.log')

class Link < ActiveRecord::Base
	validates_uniqueness_of :image_url
	def caption
		"<a href='#{self.thread_url}'>#{self.title}</a>"
	end
end

