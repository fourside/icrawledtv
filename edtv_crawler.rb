# encoding : utf-8
require 'rubygems'
require 'mechanize'
require File.dirname(__FILE__) + '/link'
require File.dirname(__FILE__) + '/tumblr_poster'

class EdtvCrawler

	def initialize
		@agent = Mechanize.new do |s|
			s.user_agent_alias = 'Mac Safari'
			s.max_history  = 1
		end
	end

	def main
		subbacks.each do |subback|
			save_links(subback)
		end
		puts "#{File.basename(__FILE__)} @#{Time.now}"
	end

	def subbacks
		YAML.load_file(File.dirname(__FILE__) + '/subbacks.yaml')
	end

# key: thread url
# value : thread title
	def thread_urls(subback_url)
		links = {}
		@agent.get(subback_url)
		@agent.page.encoding = 'CP932'
		@agent.page.search("//small[@id='trad']/a").each do |elem|
			url = @agent.page.base.href + elem['href'].gsub(/l50/, '')
			title = elem.inner_text.gsub(/^\d+:/, '').gsub(/\(\d+\)$/, '').strip
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

	def save_links(subback)
		thread_urls(subback['url']).each do |url, title|
			scrapelinks(url).each do |img|
				link = Link.new
				link.image_url, link.thread_url, link.title, link.tv = img, url, title, subback['tv']
				link.save
			end
		end
	end
end

if __FILE__ == $0
	EdtvCrawler.new.main
end
