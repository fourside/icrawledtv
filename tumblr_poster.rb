# encoding : utf-8
require 'oauth'
require 'json'
require 'yaml'
require 'active_support'
require File.dirname(__FILE__) + '/link'

class TumblrPoster
	def initialize
		tokens = YAML.load_file(File.dirname(__FILE__) + '/tokens.yaml')
		@consumer = OAuth::Consumer.new(
			tokens[:api][:apikey],
			tokens[:api][:seckey],
			:site => 'http://api.tumblr.com',
			:request_token_path => '/oauth/request_token',
			:authorize_path => '/oauth/authorize',
			:access_token_path => '/oauth/access_token',
			:oauth_version => '1.0a',
		)
		@access_token = OAuth::AccessToken.new(
			@consumer,
			tokens[:oauth][:access_token],
			tokens[:oauth][:access_token_sec],
		)
	end

	def get_tokens
		@consumer.site = 'http://www.tumblr.com'
		request_token = @consumer.get_request_token
		puts request_token.authorize_url # for access from browser and get verifier parameter
		puts 'Input oauth verifier:' # paste!
		verifier = Kernel.gets
		verifier.chomp!
		access_token = request_token.get_access_token(:oauth_verifier => verifier)
		puts access_token.token # paste to tokens.yaml
		puts access_token.secret
	end

	def main
		links = Link.where(:is_posted => false)
		list_params(links).each do |params|
			res = post_images(params)
			mark(params) if res['meta']['status'] == '201'
		end
		delete_a_week_ago
	end

	def list_params(links)
		list = []
		links.each do |link|
			list << params = {
				"type"    => "photo",
				"state"   => "queue",
				"caption" => link.title,
				"source"  => link.image_url
			}
		end
		list
	end

	def post_images(params)
		base_hostname = 'icrawledtv.tumblr.com'
		path = "/v2/blog/#{base_hostname}/post"
		response = @access_token.post(path, params)
		res = JSON.parse(response.body)
	end

# make is_posted true
	def mark(params)
		link = Link.where("image_url = '#{params['source']}'").first
		link.is_posted = true
		link.save
	end

	def delete_a_week_ago
		a_week_ago = Time.now - 1.week
		Link.delete_all("created_at <= '#{a_week_ago}'")
	end
end

#TumblrPoster.new.get_tokens
if __FILE__ == $0
	TumblrPoster.new.main
end
