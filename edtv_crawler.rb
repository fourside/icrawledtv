# encoding : utf-8
require 'rubygems'
require 'mechanize'
require 'open-uri'
require 'RMagick'
# TODO
# thread
# except thread filer

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
        begin
          local_file = download_img(img_url)
          next unless local_file
          raise "file size is zero: #{local_file}" if File.size(local_file) == 0
          thumbnail = scale_img(local_file)
          link.image_url, link.thread_url, link.title, link.tv      =
          img_url,        thread_url,      title,      subback_name
          link.save
        rescue => e
          p e
          p img_url
        end
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
        elem.inner_text.split(/ |　/).each do |url|
          #next unless /ttp:\/\/(?:www\.)?(?:dotup|iup|10up|epcan|jlab|tv|uproda|rupan|ruru2|tv2ch|motto-jimidane|file\.jabro|hayabusa|folderman|live2|age2|pa4\.dip\.jp).*\.(?:jpg|gif|png|jpeg)$/i =~ url
          unless /ttp:\/\/(?:www\.)?(?:dotup|iup|10up|epcan|jlab|tv|uproda|rupan|ruru2|tv2ch|motto-jimidane|file\.jabro|hayabusa|folderman|live2|age2|pa4?\.dip\.jp|up2?\.pandoravote\.net|long\.2chan\.tv|fat\.5pb\.org|up\.null-x|cap\d{3}\.areya|tv\.dee|fastpic\.jp|livetests\.info|katsakuri\.sakura).*\.(?:jpg|gif|png|jpeg)$/i =~ url
            File.open("except_url.txt", "a") {|file| file.write(url + "\n") } if url.index('ttp')
            next
          end
          url = 'h' + url unless url[0] == 'h'
          list << url
        end
      end
    end
    list
  end

  def download_img url, path_prefix = File.dirname(__FILE__) + '/public/img/'
    filename = path_prefix + File.basename(url)
    return nil if File.exist?(path_prefix + filename)
    open(filename, 'wb') do |file|
      open(url) do |resource|
        file.write(resource.read)
      end
    end
    filename
  end

  def scale_img file, scale = 0.5
    thumnail = Magick::Image.read(file).first.scale(scale)
    file_prefix = 'thumbnail_'
    output_dir  = File.dirname(__FILE__) + '/public/img/thumbnail/'
    outfile = output_dir + file_prefix + File.basename(file)
    thumnail.write(outfile)
  end

end

if __FILE__ == $0
  EdtvCrawler.new.main
end
