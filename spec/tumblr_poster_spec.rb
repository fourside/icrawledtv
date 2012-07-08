# encoding: utf-8
require 'rspec'
require '../tumblr_poster'
require '../db/001_create_links'
require '../db/002_add_column_links'
require '../db/003_add_column_img_hash_links'

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
			l.image_url = 'http://example.com/image.jpg'
			l.thread_url = 'http://example.com/'
		end
	end

	describe "when make params to post from links" do
		before do
			@params = @tumblr_poster.get_params(@link)
		end
		it "gets Hash" do
			@params.class.should be Hash
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
			@params['caption'].should == "<a href='http://example.com/'>NHKを見てn倍賢く</a>"
		end
		it "makes params, that has value of source" do
			@params['source'].should == 'http://example.com/image.jpg'
		end
	end

	describe "when posted image to Tumblr" do
		before do
			@link.save
			@params = @tumblr_poster.get_params(@link)
		end
		it "should mark is_posted true" do
			@tumblr_poster.mark(@params)
			Link.where(:image_url => @params['source']).first.is_posted.should be true
		end
	end

	describe "when 1 week passed" do
		before do
			@params = @tumblr_poster.get_params(@link)
			@oldlink = Link.where(:image_url => @params['source']).first
			@oldlink.created_at = @oldlink.created_at - 7.days - 1.hour
			@oldlink.save
		end
		it "should delete records created at 1 week ago" do
			@tumblr_poster.delete_a_week_ago
			Link.where(:image_url => @params['source']).first.should be nil
		end
	end

	describe "when it reached a limit" do
		before do
			@res400 = {"meta"=>{"status"=>400, "msg"=>"Bad Request"}, "response"=>{"errors"=>{"type"=>"Oh no! You've reached your photo upload limit for today. Please come again tomorrow!"}}}
		end
		it "should be false" do
			@tumblr_poster.reach_limit?(@res400).should be_true
		end
	end

	describe "when it errored uploading photo" do
		before do
			@res400 = {"meta"=>{"status"=>400, "msg"=>"Bad Request"}, "response"=>{"errors"=>["Error uploading photo."]}}
		end
		it "should be false" do
			@tumblr_poster.reach_limit?(@res400).should be_false
		end
	end
end


