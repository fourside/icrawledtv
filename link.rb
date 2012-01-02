require 'rubygems'
require 'active_record'
require 'logger'

ActiveRecord::Base.establish_connection(
	:adapter => 'sqlite3',
	:database => File.join(File.dirname(__FILE__), '/db/links.db')
	)
ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), '/database.log'))

class Link < ActiveRecord::Base
	def caption
		"<a href='#{self.thread_url}'>#{self.title}</a>"
	end
end
