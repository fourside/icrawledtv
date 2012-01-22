require 'net/http'
require 'open-uri'
require 'digest/md5'
require 'pp'
require File.dirname(__FILE__) + '/link'

def main
	Link.where(:is_posted => false).order(:created_at).each do |link|
		begin
			if deadlink?(link.image_url)
				mark(link)
			else
				link.img_hash = img_hash(link.image_url)
				unless link.save
					mark(link)
				end
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

def img_hash(url)
	url = 'h' + url if url =~ /^ttp/
	open(url) do |data|
		Digest::MD5.hexdigest data.read
	end
end

if __FILE__ == $0
	main
end
