require 'rubygems'
require 'sinatra'
require 'haml'
require 'shotgun'
require File.dirname(__FILE__) + '/link'

helpers do
  include Rack::Utils; alias_method :h, :escape_html
end

get '/' do
  @links = Link.select(:tv).where('tv is not null').group(:tv)
  haml :index
end

get '/rss' do
  content_type 'text/xml; charset=utf-8'
  @links = Link.where(:is_posted => 'f').order('created_at desc').limit(200)
  @title = ''
  haml :rss
end

get '/rss/:tv' do
  content_type 'text/xml; charset=utf-8'
  @links = Link.where(:is_posted => 'f', :tv => params[:tv]).order('created_at desc').limit(200)
  @title = ' - ' + params[:tv]
  haml :rss
end
__END__

@@ index
!!!
%html
  %body
    %h1 icarwledtv
    %h3 feeds
    %ul
      - @links.each do |link|
        %li
          %a{:href => "/rss/#{h(link.tv)}"} #{h(link.tv)}

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
        %description= "&lt;img src='#{h(link.image_url)}' /&gt;"
        %link #{h(link.thread_url)}
        %guid #{link.id}
        %pubDate #{link.created_at}
