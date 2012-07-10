# encoding: utf-8
require 'rspec'
require '../link'
require '../db/001_create_links'


describe Link do
  before(:all) do
    ActiveRecord::Base.establish_connection(
      :adapter => 'sqlite3',
      :database => ':memory:'
    )
    ActiveRecord::Base.logger = nil
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
      @link1 = Link.new
      @link1.image_url = @link.image_url
      @link1.thread_url = 'http://piyo/'
      @link1.title = 'NHKを見て100000倍賢く'
    end

    it "should fail" do
      @link1.save.should be false
    end
  end

  describe "when call caption method" do
    it "should return anchor of html to link thread url" do
      @link.caption.should == "<a href='#{@link.thread_url}'>#{@link.title}</a>"
    end
  end

end
