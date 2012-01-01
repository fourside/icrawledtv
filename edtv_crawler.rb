# encoding : utf-8
require 'rubygems'
require 'mechanize'
require File.dirname(__FILE__) + '/link'

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

# key: thread url
# value : thread title
	def thread_urls
		links = {}
		@agent.page.search("//small[@id='trad']/a").each do |elem|
			if elem.inner_text =~ /NHK教育を見て/
				url = BASEURL + elem['href'].gsub(/l50/, '')
				links[url] = elem.inner_text
			end
		end
		links
	end

# in bbs thread
	def scrapelinks(url)
		@agent.get(url)
		@agent.page.encoding = 'CP932'
		list = []
		@agent.page.search("//dd").each do |elem|
			if elem.inner_text.index('ttp')
				elem.inner_text.split.each do |s|
					next unless /^h?ttp:\/\/(?:www\.)?(?:iup|10up|epcan|jlab|tv|uproda|rupan|ruru2).*\.(?:jpg|gif|png|jpeg)$/ =~ s
					s = 'h' + s unless s[0] == 'h'
					list << s
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
				rescue
				end
			end
		end
	end
end

