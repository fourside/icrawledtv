require 'rubygems'
require 'sinatra'
require 'haml'
require 'shotgun'
require File.dirname(__FILE__) + '/link'
require File.dirname(__FILE__) + '/page'

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
  def set_cookie id # entry point
    response.set_cookie('s', :value => id, :expires => Time.now + (60*60*24*7))
  end
  def get_cookie
    request.cookies['s']
  end
  # for use of SQL between phrase
  def get_id_range origin, current_page # FIXME clunky name
    from = origin.to_i - ((current_page - 1) * Page::COUNT_OF_ENTRIES)
    to   = from - Page::COUNT_OF_ENTRIES
    to...from # from is larger id number.
  end
  def caption # TODO move from Link object method => not needed.
    #"<a href='#{self.thread_url}'>#{self.title}</a>"
  end
end

configure do
  set :sessions, true
end

before do
  @host = "#{request.scheme}://#{request.host}:#{request.port}" # FIXME wrong name
  @title = 'icrawledtv'
  @base_url = '/'
  @categories = Link.group(:tv) unless /rss/ =~ request.path
end

before '/tv/:tv' do
  @title += ' - ' + params[:tv]
  @base_url = "/tv/#{params[:tv]}/"
end

get '/:page' do
  pass if params[:page] =~ /^\d+/ || get_cookie
  @page  = Page.new(params[:page].to_i, Link.count)
  origination = get_cookie
  from = origination.to_i - ((@page.current - 1) * Page::COUNT_OF_ENTRIES)
  to   = from - Page::COUNT_OF_ENTRIES
  @links = Link.where(:id => to...from).order('id desc')
  haml :index, :format => :html5
end

get '/' do
  @page = Page.new(1, Link.count)
  @links = Link.order('id desc').limit(Page::COUNT_OF_ENTRIES)
  set_cookie(@links.first.id)
  haml :index, :format => :html5
end

get '/rss' do
  content_type 'text/xml; charset=utf-8'
  @links = Link.order('id desc').limit(200)
  haml :rss
end

get '/rss/:tv' do
  content_type 'text/xml; charset=utf-8'
  @links = Link.where(:tv => params[:tv]).order('id desc').limit(200)
  @title += ' - ' + params[:tv]
  haml :rss
end

get '/tv/:tv/:page' do
  @tv   = params[:tv]
  @page  = Page.new(params[:page].to_i, Link.where(:tv => @tv).size)
  origination = get_cookie
  from = origination.to_i - ((@page.current - 1) * Page::COUNT_OF_ENTRIES)
  to   = from - Page::COUNT_OF_ENTRIES
  @links = Link.where(:tv => @tv, :id => to...from).order('id desc')
  haml :index, :format => :html5
end

get '/tv/:tv' do
  @tv   = params[:tv]
  @page = Page.new(1, Link.where(:tv => @tv).size)
  @links = Link.where(:tv => @tv).order('id desc').limit(Page::COUNT_OF_ENTRIES)
  set_cookie(@links.first.id)
  haml :index, :format => :html5
end

get '/id/:id' do
  redirect '/' unless params[:id] =~ /^\d+/
  id = params[:id].to_i
  @page = Page.new(1, Link.count("id < id"))
  @links = Link.where(:id => (id - Page::COUNT_OF_ENTRIES)..id).order('id desc')
  set_cookie(id)
  haml :index, :format => :html5
end

error do
  'an error occured. ' + env['sinatra.error'].name
end

__END__

@@ index
!!!
%html
  %head
    %title #{@title}
    %meta{:charset => 'utf-8'}
    %base{:href => "#{@base_url}"}
    %link{:href => "/css/common.css", :rel => "stylesheet", :type => "text/css"}
    %link{:rel => "alternate", :type => "application/rss+xml", :title => "RSS", :href => "rss"}
  %body
    %div.container
      %h1
        %a{:href => '/'} #{@title}
      %ul.categories
        - @categories.each do |cat|
          %li.tv
            %a{:href => "/tv/#{h(cat.tv)}"} #{h(cat.tv)}
      %p #{@page.current} page
      %div.hfeed
        - @links.each do |link|
          %div.hentry
            %h3{:class => "entry-title", :id => link.id}
              %p
                %a{:href => "#{link.thread_url}"} #{h(link.title)}
            %div.entry-content
              %p
                %a{:href => "/img/#{File.basename(link.image_url)}", :target => "_blank", :rel => "bookmark"}
                  %img{:src => "/img/thumbnail/thumbnail_#{File.basename(link.image_url)}"}
            %div.entry-meta
              %ul
                %li
                  %a{:href => "#{link.image_url}"} #{link.image_url}
                %li
                  id:
                  %a{:href => "/id/#{h(link.id)}"} #{h(link.id)}
                %li
                  %a{:href => "/tv/#{link.tv}", :rel => "tag"} [#{link.tv}]
                %li.author.vcard{:style => "display:none"}
                  %span.nickname.fn me
                %li.published
                  %abbr.updated{:title => "#{link.created_at.iso8601}"} #{link.created_at}
      %p.pager
        - if @page.prev
          %a{:href => "#{@page.prev}", :rel => 'prev'}prev
          &nbsp;|
        - if @page.next
          %a{:href => "#{@page.next}", :rel => 'next'}next

@@ rss
!!!XML utf-8
%rss{:version => "1.0",  "xmlns:atom" => "http://www.w3.org/2005/Atom"}
  %channel
    %title icrawledtv #{h(@title)}
    %link icrawledtv.heroku.com/
    %description icrawledtv #{h(@title)}
    <atom:link href="/rss" rel="self" type="application/rss+xml" />
    - @links.each do |link|
      %item
        %title #{h(link.title)}
        %description= "&lt;img src='#{h(@host) + h(link.image_url)}' /&gt;"
        %link #{h(link.thread_url)}
        %guid #{link.id}
        %pubDate #{link.created_at}
