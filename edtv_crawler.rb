# encoding: utf-8
require 'rubygems'
require 'mechanize'

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
			if elem.inner_text =~ /ttp.*(?:jpg|gif|png|jpeg)/
				elem.inner_text.split(' ').each do |s|
					url = s if s =~ /h?ttp:\/\/(www\.)?(?:10up|epcan|jlab|tv|uproda|rupan).*(?:jpg|gif|png|jpeg)/
					url = 'h' + url unless url[0] == 'h'
					list << url
				end
			end
		end
		list
	end
end
