# encoding: utf-8
require 'rspec'
require '../link'
require '../db/001_create_links'


describe Link do
	before do
		ActiveRecord::Base.establish_connection(
			:adapter => 'sqlite3',
			:database => ':memory:'
		)
		CreateLinks::up
		@link = Link.new
		@link.image_url = 'http://hoge/hoge.jpg'
		@link.thread_url = 'http://fuga/'
		@link.title = 'NHKを見て99999倍賢く'
	end

	describe "when Link saves" do
		it "should success" do
			@link.save.should be_true
		end
	end

	describe "when Link saves with the duplicated image url" do
		before do
			@link.save
			@link = Link.new
			@link.image_url = 'http://hoge/hoge.jpg'
			@link.thread_url = 'http://piyo/'
			@link.title = 'NHKを見て100000倍賢く'
		end

		it "should fail" do
			proc {
				@link.save
			}.should raise_error(ActiveRecord::StatementInvalid)
		end
	end

end
