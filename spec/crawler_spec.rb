# encoding: utf-8
require 'rspec'
require '../edtv_crawler'

describe EdtvCrawler do
	before do
		@crawler = EdtvCrawler.new
	end

	describe "when call thread_urls method" do
		before do
			@thread_urls = @crawler.thread_urls
		end

		it "should get hash" do
			@thread_urls.class.should be Hash
		end

		it "should get hash that key is url" do
			@thread_urls.keys.each do |k|
				k.should =~ /http:\/\//
			end
		end

		it "should get hash that value is title" do
			@thread_urls.values.each do |v|
				v.should =~ /NHK教育を見て/
			end
		end
	end

	describe "when call scrapelinks method" do
		before do
			urls = @crawler.thread_urls.keys
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

end
