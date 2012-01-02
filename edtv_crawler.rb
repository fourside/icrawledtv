# encoding : utf-8
require 'rubygems'
require 'mechanize'
require File.dirname(__FILE__) + '/link'
require File.dirname(__FILE__) + '/tumblr_poster'

class EdtvCrawler
	BASEURL = 'http://hayabusa2.2ch.net/test/read.cgi/liveetv/'
	SUBBACK = 'http://hayabusa2.2ch.net/liveetv/subback.html'

	def initialize
		@agent = Mechanize.new do |s|
			s.user_agent_alias = 'Mac Safari'
			s.max_history  = 2
		end
		@agent.get(SUBBACK)
		@agent.page.encoding = 'CP932'
	end

	def main
		save_links
		#TumblrPoster.new.run
	end

# key: thread url
# value : thread title
	def thread_urls
		links = {}
		@agent.page.search("//small[@id='trad']/a").each do |elem|
			#next unless elem.inner_text =~ /NHK教育を見て/
			url = BASEURL + elem['href'].gsub(/l50/, '')
			title = elem.inner_text.gsub(/^\d+:/, '').gsub(/\(\d+\)/, '').strip
			links[url] = title
		end
		links
	end

# in bbs thread
	def scrapelinks(thread_url)
		@agent.get(thread_url)
		@agent.page.encoding = 'CP932'
		list = []
		@agent.page.search("//dd").each do |elem|
			if elem.inner_text.index('ttp')
				elem.inner_text.split.each do |url|
					next unless /^h?ttp:\/\/(?:www\.)?(?:iup|10up|epcan|jlab|tv|uproda|rupan|ruru2).*\.(?:jpg|gif|png|jpeg)$/ =~ url
					url = 'h' + url unless url[0] == 'h'
					list << url
				end
			end
		end
		list
	end

	def save_links
		thread_urls.each do |url, title|
			scrapelinks(url).each do |img|
				link = Link.new
				link.image_url, link.thread_url, link.title = img, url, title
				begin
					link.save
				rescue # ignore exception
				end
			end
		end
	end
end

if __FILE__ == $0
	EdtvCrawler.new.main
end
