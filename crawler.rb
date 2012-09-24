# encoding : utf-8
require 'rubygems'
require 'open-uri'
require 'uri'
require 'RMagick'
require File.dirname(__FILE__) + '/link'

class Board
  def initialize board, filter
    @is_bourbon_house = false
    @tv      = board['tv']
    @threads = filter_threads(scrape_thread_list(board['url']), filter)
  end
  attr_reader :threads, :tv

  def filter_threads threads, filter
    threads.deny(filter['deny']).allow(filter['allow'])
  end

  # make Hash object: key is thread url, value is thread title.
  def scrape_thread_list board_url
    threads = {}
    # subject.txt is text/plain(sjis)
    open(board_url+'subject.txt', 'r:Shift_JIS') do |response|
      if response.status[0] != '200'
        @is_bourbon_house = true
        return {} # return Hash for filter_threads method
      end
      response.each_line do |line|
        line = line.encode('UTF-8', invalid: :replace, undef: :replace)
        # "1347844405.dat<>title (int)\n"
        /^(\d+\.dat)<>(.+) \(\d+\)/ =~ line
        dat_url = board_url + 'dat/' + $1
        threads[dat_url] = $2
      end
    end
    threads
  end

  def bourbon_house?
    @is_bourbon_house
  end

end

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

# parse a thread content, and return Array of img src text
class ThreadParser
  # param is thread url
  # return array of anchor text linked to image file
  def parse url
    image_urls = []
    open(url, 'r:Shift_JIS') do |response| # http response body is normally text/plain
      response.each_line do |line|
        # name<>mail<>yyyy/mm/dd(月) HH:MM:SS.mm ID:id<>content<>thread title at only first line
        content = line.encode('UTF-8', invalid: :replace, undef: :replace).split('<>')[3]
        next if content.nil? || ! content.include?('ttp')
        image_urls.push(extract_url(content))
      end
    end
    image_urls.flatten
  end

  def extract_url text
    text.scan(/(h?ttp:\/\/[^ ]+?(?:jpe?g|png|gif))/i)
  end

end

class UplodaImage
  def initialize url
    @uri = URI.parse(url)
    @uri.scheme = 'http' if @uri.scheme == 'ttp'
  end
  attr_reader :uri

  def download
    unless uploader? @uri.host
      File.open("except_url.txt", "a") {|file| file.write(@uri.to_s + "\n") }
      raise DownloadException.new("not targeted uploader: #{@uri.to_s}")
    end
    path_prefix = File.dirname(__FILE__) + '/public/img/'
    filename = path_prefix + File.basename(@uri.to_s)
    raise DownloadException.new("already exists: #{filename}") if File.exist?(path_prefix + filename)
    open(filename, 'wb') do |file|
      open(@uri.to_s) do |resource|
        file.write(resource.read)
      end
    end
    raise DownloadException.new("file is empty: #{filename}") if File.size(filename) == 0
    raise DownloadException.new("file is not image: #{filename}") unless image?(filename)
    filename
  end

  def make_thumbnail file
    scale = 0.5
    thumbnail = Magick::Image.read(file).first.scale(scale)
    file_prefix = 'thumbnail_'
    output_dir  = File.dirname(__FILE__) + '/public/img/thumbnail/'
    outfile = output_dir + file_prefix + File.basename(file)
    thumbnail.write(outfile)
  end

  # TODO: make this regexp be maintainnable
  def uploader? host
    /(?:dotup|iup|10up|epcan|jlab|tv|uproda|rupan|ruru2|tv2ch|motto-jimidane|file\.jabro|hayabusa|folderman|live2|age2|pa4?\.dip\.jp|up2?\.pandoravote\.net|long\.2chan\.tv|fat\.5pb\.org|up\.null-x|cap\d{3}\.areya|tv\.dee|fastpic\.jp|livetests\.info|katsakuri\.sakura|niceboat|2ch\.at|2chlog\.com|ana\.uploda|livecap|up3\.viploader)$/i =~ host
  end

  def image? file
    /image data/i =~ `file #{file}`
  end
end

class Crawler
  def drive
    links = []
    Dir.glob(File.dirname(__FILE__) + '/subbacks/*yaml').each do |subback_file|
      subbacks = YAML.load_file(subback_file)
      links = get_links(subbacks)
      links.sort {|a, b| a.tv <=> b.tv}.each do |link|
        link.save
      end
    end
  rescue => e
    $stderr.puts "#{e.class}|#{e.message}|#{e.backtrace}|#{Time.now}"
  end

  def get_links subbacks
    links = []
    subbacks['boards'].each do |board|
      Board.new(board, subbacks['filter']).threads.each do |thread_url, thread_title|
        ThreadParser.new.parse(thread_url).each do |image_url|
          begin
            link = Link.new
            uploda_image = UplodaImage.new(image_url)
            filename = uploda_image.download
            uploda_image.make_thumbnail filename
            link.title      = thread_title
            link.thread_url = thread_url
            link.tv         = board['tv']
            link.image_url  = uploda_image.uri
            links << link
          rescue DownloadException # do nothing
          rescue => e
            $stderr.puts "#{e.class}|#{e.message}|#{e.backtrace}|#{Time.now}"
          end
        end
      end
    end
    links
  end

end

class DownloadException < StandardError; end

Crawler.new.drive if __FILE__ == $0
