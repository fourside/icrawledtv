# icrawledtv
## description
i-crawl-edtv

教育テレビの実況からキャプチャを探してTumblrにポストします

## preparation
- ./tokens.yaml
	- Tumblrの認証用のキーを記述しておきます
- ./db/links.db
	- ./db/001_create_links.rbを実行して生成しておきます

## usage
	ruby ./edtv_crawler.rb
