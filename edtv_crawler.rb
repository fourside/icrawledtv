# encoding : utf-8
require 'rubygems'
require 'mechanize'
require 'open-uri'
require File.dirname(__FILE__) + '/link'

class EdtvCrawler

  def initialize
    @agent = Mechanize.new do |agent|
      agent.user_agent_alias = 'Mac Safari'
      agent.max_history  = 1
    end
  end

  def main
    yaml = File.dirname(__FILE__) + '/subbacks.yaml'
    YAML.load_file(yaml).each do |subback|
      save_links subback['url'], subback['tv']
    end
  end

  def save_links subback_url, subback_name
    get_threads(subback_url).each do |thread_url, title|
      get_img_urls(thread_url).each do |img_url|
        link = Link.new
        link.image_url, link.thread_url, link.title, link.tv =
        img_url,        thread_url,      title,      subback_name
        link.save
      end
    end
  end

# key: thread url
# value : thread title
  def get_threads subback_url
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
  def get_img_urls thread_url
    @agent.get(thread_url)
    @agent.page.encoding = 'CP932'
    list = []
    @agent.page.search("//dd").each do |elem|
      if elem.inner_text.index('ttp')
        elem.inner_text.split.each do |url|
          next unless /^h?ttp:\/\/(?:www\.)?(?:dotup|iup|10up|epcan|jlab|tv|uproda|rupan|ruru2).*\.(?:jpg|gif|png|jpeg)$/ =~ url
          url = 'h' + url unless url[0] == 'h'
          list << url
        end
      end
    end
    list
  end

end

if __FILE__ == $0
  EdtvCrawler.new.main
end
