require 'rubygems'
require 'sinatra'
require 'haml'
require 'shotgun'
require File.dirname(__FILE__) + '/link'

helpers do
  include Rack::Utils; alias_method :h, :escape_html
end

before do
  @host = "#{request.scheme}://#{request.host}:#{request.port}"
end

get '/:page' do

  redirect '/' unless params[:page] =~ /^\d+/
  @categories = Link.group(:tv)
  count_per_page = 10
  @page  = params[:page].to_i
  @links = Link.where(:is_posted => 'f').order('created_at desc').offset(@page * count_per_page - 1).limit(count_per_page)
  last_page = (Link.where(:is_posted => 'f').size / count_per_page).ceil
  @next = @page != last_page ? @page + 1 : nil
  @prev = @page > 1 ? @page - 1 : nil
  haml :index
end

get '/' do
  @categories = Link.group(:tv)
  count_per_page = 10
  @page = 1 unless @page
  @links = Link.where(:is_posted => 'f').order('created_at desc').offset(@page * count_per_page - 1).limit(count_per_page)
  last_page = (Link.where(:is_posted => 'f').size / count_per_page).ceil
  @next = @page != last_page ? @page + 1 : nil
  @prev = @page > 1 ? @page - 1 : nil
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

get '/tv/:tv/:page' do
  @page  = params[:page] =~ /^\d+$/ ? params[:page].to_i : nil
  pass
end

get '/tv/:tv/?*' do
  content_type 'text/html; charset=utf-8'
  count_per_page = 10
  @page = 1 unless @page
  @tv   = params[:tv]
  @links = Link.where(:tv => @tv).order('created_at desc').offset(@page * count_per_page - 1).limit(count_per_page)
  last_page = (Link.where(:tv => @tv).size / count_per_page).ceil
  @next = @page != last_page ? @page + 1 : nil
  @prev = @page > 1 ? @page - 1 : nil
  haml :tv
end

__END__

@@ index
!!!
%html
  %head
    %title icrawledtv
    %meta{:charset => 'utf-8'}
    %link{:href => "/css/common.css", :rel => "stylesheet", :type => "text/css"}
    %link{:rel => "alternate", :type => "application/rss+xml", :title => "RSS", :href => "/rss"}
  %body
    %div.container
      %h1
        %a{:href => '/'}icrawledtv
      %ul.categories
        - @categories.each do |cat|
          %li.tv
            %a{:href => "/tv/#{h(cat.tv)}"} #{h(cat.tv)}
      %p #{@page} page
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
                  %a{:href => "/#{link.tv}", :rel => "tag"} [#{link.tv}]
                %li.author.vcard{:style => "display:none"}
                  %span.nickname.fn me
                %li.published
                  %abbr.updated{:title => "#{link.created_at.iso8601}"} #{link.created_at}
      %p.pager
        - if @prev
          %a{:href => "/#{@prev}", :rel => 'prev'}prev
          &nbsp;|
        - if @next
          %a{:href => "/#{@next}", :rel => 'next'}next

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

@@ tv
!!!
%html
  %head
    %title icrawledtv - #{h(@tv)}
    %meta{:charset => 'utf-8'}
    %link{:href => "/css/common.css", :rel => "stylesheet", :type => "text/css"}
    %link{:rel => "alternate", :type => "application/rss+xml", :title => "RSS", :href => "/rss/#{@tv}"}
  %body
    %div.container
      %h1
        %a{:href => '/'}icrawledtv
      %h2
        %a{:href => "/tv/#{h(@tv)}"}#{h(@tv)}
      %p #{@page} page
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
                  %a{:href => "/#{link.tv}", :rel => "tag"} [#{link.tv}]
                %li.author.vcard{:style => "display:none"}
                  %span.nickname.fn me
                %li.published
                  %abbr.updated{:title => "#{link.created_at.iso8601}"} #{link.created_at}
      %p.pager
        - if @prev
          %a{:href => "/tv/#{@tv}/#{@prev}", :rel => 'prev'}prev
          &nbsp;|
        - if @next
          %a{:href => "/tv/#{@tv}/#{@next}", :rel => 'next'}next
