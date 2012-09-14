# encoding: utf-8
require 'rspec'
require '../edtv_crawler'
require '../db/001_create_links'
require '../db/002_add_column_links'
require '../db/003_add_column_links_image_local_path'

describe EdtvCrawler do
  before(:all) do
    @crawler = EdtvCrawler.new
    @subback = {
      'url' => "http://hayabusa2.2ch.net/livenhk/subback.html",
      'tv' => 'ntv'}
  end

  describe "when call get_threads method" do
    before do
      @thread_urls = @crawler.get_threads(@subback['url'])
    end

    it "should get hash" do
      @thread_urls.class.should be Hash
    end

    it "should get hash that key is url" do
      @thread_urls.keys.each do |k|
        k.should =~ /http:\/\//
      end
    end

    it "should get hash that value is title, which starts no number" do
      @thread_urls.values.each do |v|
        v.should =~ /^[^\d]+/
      end
    end
  end

  describe "when call get_img_urls method" do
    before do
      urls = @crawler.get_threads(@subback['url']).keys
      @scrapelinks = @crawler.get_img_urls(urls[1])
    end

    it "should get array" do
      @scrapelinks.class.should be Array
    end

    it "should get array that is image url" do
      @scrapelinks.each do |l|
        l.should =~ /\Ahttp:\/\/.*\.(?:jpg|gif|png|jpeg)\z/
      end
    end

  end

  describe "when call save_link method" do
    before do
      ActiveRecord::Base.establish_connection(
        :adapter => 'sqlite3',
        :database => ':memory:'
      )
      CreateLinks::up
      AddColumnLinks::up
      AddColumnLinksImageLocalPath::up
    end
    it "should save image link" do
      @crawler.save_links @subback['url'], @subback['tv']
      Link.find(:all).size.should have_at_least(1).items
    end
  end

  describe "when call download_img" do
    before do
      @url = "https://www.google.co.jp/images/srpr/logo3w.png"
      @file = File.basename(@url)
    end
    it "should save image file to ./img/" do
      @crawler.download_img @url
      File.size("../img/#{@file}").should_not be_zero
    end
    after do
      FileUtils.rm "../img/#{@file}"
    end
  end

end
