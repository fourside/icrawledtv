# encoding: utf-8
require 'rspec'
require '../edtv_crawler'
require '../db/001_create_links'
require '../db/002_add_column_links'

describe EdtvCrawler do
	before(:all) do
		@crawler = EdtvCrawler.new
		@subback = {
			'url' => "http://hayabusa2.2ch.net/livenhk/subback.html",
			'tv' => 'ntv'}
	end

	describe "when call thread_urls method" do
		before do
			@thread_urls = @crawler.thread_urls(@subback['url'])
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

	describe "when call scrapelinks method" do
		before do
			urls = @crawler.thread_urls(@subback['url']).keys
			@scrapelinks = @crawler.scrapelinks(urls[1])
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
		end
		it "should saved image link" do
			@crawler.save_links(@subback)
			Link.find(:all).size.should have_at_least(1).items
		end
	end

	describe "when call subbacks" do
		before do
			@subbacks = @crawler.subbacks
		end
		it "should return array of subback" do
			@subbacks.class.should be Array
		end
		it "should return array of subback, which element is hash" do
			@subbacks.first.class.should be Hash
		end
		it "should return array of subback, which hash has url" do
			@subbacks.first['url'].should match /^http:/
		end
		it "should return array of subback, which hash has tv name" do
			@subbacks.first['tv'].should match /^(etv|nhk|bs|mx)$/
		end
	end

end
