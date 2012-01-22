require 'net/http'
require 'pp'
require File.dirname(__FILE__) + '/link'

def main
	Link.where(:is_posted => false).order(:created_at).each do |link|
		begin
			if deadlink?(link.image_url)
				mark(link)
			end
		rescue => e
			pp e
		end
	end
end

def deadlink?(url)
	url = 'h' + url if url =~ /^ttp/
	begin
		Net::HTTP.get_response(URI.parse(url)).code != "200"
	rescue
		false
	end
end

def mark(link)
	link.is_posted = true
	link.save
end

if __FILE__ == $0
	main
end
