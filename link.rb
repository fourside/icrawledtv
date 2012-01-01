require 'rubygems'
require 'active_record'

class Link < ActiveRecord::Base
	ActiveRecord::Base.establish_connection(
		:adapter => 'sqlite3',
		:database => File.join(File.dirname(__FILE__), '/db/links.db')
		)
	ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), '/database.log'))
end
