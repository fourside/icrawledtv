# encoding : utf-8
require 'oauth'
require 'json'
require 'yaml'
require 'active_support'
require File.dirname(__FILE__) + '/link'

class TumblrPoster
	def init
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
		init
		@consumer.site = 'http://www.tumblr.com'
		request_token = @consumer.get_request_token
		puts request_token.authorize_url # for access by browser and get verifier parameter
		puts 'Input oauth verifier:' # paste!
		verifier = Kernel.gets
		verifier.chomp!
		access_token = request_token.get_access_token(:oauth_verifier => verifier)
		puts access_token.token # paste to tokens.yaml
		puts access_token.secret
	end

	def run
		init
		@log = Logger.new('./log.log')
		@log.level = Logger::DEBUG
		Link.where(:is_posted => false).order(:created_at).each do |link|
			params = get_params(link)
			res = post_image(params)
			mark(params) if res['meta']['status'] == 201
		end
		delete_a_week_ago
	end

	def get_params(link)
		params = {
			"type"    => "photo",
			"state"   => "published",
			"caption" => link.caption,
			"source"  => link.image_url
		}
	end

	def post_image(params)
		base_hostname = 'icrawledtv.tumblr.com'
		path = "/v2/blog/#{base_hostname}/post"
		response = @access_token.post(path, params)
		JSON.parse(response.body)
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

	def reach_limit?(res)
		return false unless res["response"].key?("errors")
		case res["response"]["errors"]
			when Hash
				true
			else
				false
		end
	end
end

#TumblrPoster.new.get_tokens
if __FILE__ == $0
	TumblrPoster.new.run
end
