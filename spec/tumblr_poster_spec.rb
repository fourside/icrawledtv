# encoding: utf-8
require 'rspec'
require '../tumblr_poster'
require '../db/001_create_links'

describe TumblrPoster do
	before(:all) do
		ActiveRecord::Base.establish_connection(
			:adapter => 'sqlite3',
			:database => ':memory:'
		)
		CreateLinks::up
		@tumblr_poster = TumblrPoster.new
		@link = Link.new do |l|
			l.title = 'NHKを見てn倍賢く'
			l.image_url = 'http://example.com'
		end
		@links = []
		@links << @link
	end

	describe "when make params to post from links" do
		before do
			@params_list = @tumblr_poster.list_params(@links)
			@params = @params_list.first
		end
		it "gets Array" do
			@params_list.class.should be Array
		end
		it "makes params, that has key :type" do
			@params.should have_key('type')
		end
		it "makes params, that has key :state" do
			@params.should have_key('state')
		end
		it "makes params, that has key :caption" do
			@params.should have_key('caption')
		end
		it "makes params, that has key :source" do
			@params.should have_key('source')
		end
		it "makes params, that has value of type" do
			@params['type'].should == 'photo'
		end
		it "makes params, that has value of state" do
			@params['state'].should == 'queue'
		end
		it "makes params, that has value of caption" do
			@params['caption'].should == 'NHKを見てn倍賢く'
		end
		it "makes params, that has value of source" do
			@params['source'].should == 'http://example.com'
		end
	end

	describe "when posted image to Tumblr" do
		before do
			@link.save
			@params_list = @tumblr_poster.list_params(@links)
			@params = @params_list.first
			@tumblr_poster.mark(@params)
		end
		it "should mark is_posted true" do
			Link.where(:image_url => @params['source']).first.is_posted.should be true
		end
	end

	describe "when 1 week passed" do
		before do
			@params_list = @tumblr_poster.list_params(@links)
			@params = @params_list.first
			@oldlink = Link.where(:image_url => @params['source']).first
			@oldlink.created_at = @oldlink.created_at - 7.days - 1.hour
			@oldlink.save
			puts  Time.now
		end
		it "should delete records created at 1 week ago" do
			@tumblr_poster.delete_a_week_ago
			Link.where(:image_url => @params['source']).first.should be nil
		end
	end
end


