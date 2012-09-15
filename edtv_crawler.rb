# encoding : utf-8
require 'rubygems'
require 'mechanize'
require 'open-uri'
require 'uri'
require 'RMagick'
require File.dirname(__FILE__) + '/link'

class CrawlerDriver
  def drive
    crawlers = []
    links = []
    yaml = File.dirname(__FILE__) + '/' + ARGV.first
    YAML.load_file(yaml).each do |subback|
      crawlers << Thread.new do
        links << EdtvCrawler.new.run(subback)
      end
    end
    crawlers.each {|t| t.join}
    links.sort {|a, b| a.tv <=> b.tv}.each do |link|
      link.save
    end

  end
end

class EdtvCrawler
  def initialize
    @agent = Mechanize.new do |agent|
      agent.user_agent_alias = 'Mac Safari'
      agent.max_history  = 1
    end
  end

  def run subback
    save_links subback['url'], subback['tv']
  end

  def save_links subback_url, subback_name
    links = []
    get_threads(subback_url).each do |thread_url, title|
      get_img_urls(thread_url).each do |img_url|
        link = Link.new
        begin
          local_file = download_img(img_url)
          thumbnail = make_thumbnail(local_file)
          link.image_url, link.thread_url, link.title, link.tv      =
          img_url,        thread_url,      title,      subback_name
          links << link
        rescue => e
          p e
          p img_url
        end
      end
    end
    links
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
        elem.inner_text.split(/ |　/).each do |url_text|
          next unless /(h?ttp.+(?:jpe?g|gif|png))/ =~ url_text
          begin
            uri = URI.parse($1)
            uri.scheme = 'http' if uri.scheme != 'http'
            if uploader? uri.to_s
              list << uri.to_s
            else
              File.open("except_url.txt", "a") {|file| file.write(uri.to_s + "\n") } if uri.path.index(/jpe?g|png|gif/)
            end
          rescue => e
            p e unless e.class == DownloadException
          end
        end
      end
    end
    list
  end

  def uploader? url
    /ttp:\/\/(?:www\.)?(?:dotup|iup|10up|epcan|jlab|tv|uproda|rupan|ruru2|tv2ch|motto-jimidane|file\.jabro|hayabusa|folderman|live2|age2|pa4?\.dip\.jp|up2?\.pandoravote\.net|long\.2chan\.tv|fat\.5pb\.org|up\.null-x|cap\d{3}\.areya|tv\.dee|fastpic\.jp|livetests\.info|katsakuri\.sakura|niceboat|2ch\.at|2chlog\.com|ana\.uploda|livecap|up3\.viploader).*\.(?:jpg|gif|png|jpeg)$/i =~ url
  end

  def ignore
  end

  def download_img url
    path_prefix = File.dirname(__FILE__) + '/public/img/'
    filename = path_prefix + File.basename(url)
    raise DownloadException.new("already exists: #{filename}") if File.exist?(path_prefix + filename)
    open(filename, 'wb') do |file|
      open(url) do |resource|
        file.write(resource.read)
      end
    end
    raise DownloadException.new("file is empty: #{filename}") if File.size(filename) == 0
    raise DownloadException.new("file is not image: #{filename}") unless image?(filename)
    filename
  end

  def make_thumbnail file, scale = 0.5
    thumnail = Magick::Image.read(file).first.scale(scale)
    file_prefix = 'thumbnail_'
    output_dir  = File.dirname(__FILE__) + '/public/img/thumbnail/'
    outfile = output_dir + file_prefix + File.basename(file)
    thumnail.write(outfile)
  end

  def image? file
    /image data/i =~ `file #{file}`
  end

end

class DownloadException < StandardError; end

class Hash
  def deny keyword
    return self if keyword.nil?
    return {} if keyword == :all
    self.delete_if {|key, value| /#{keyword}/i =~ value }
  end
  def allow keyword
    return self if keyword.nil? || keyword == :all
    self.delete_if {|key, value| /#{keyword}/i !~ value }
  end
end

if __FILE__ == $0
  CrawlerDriver.new.drive
end
