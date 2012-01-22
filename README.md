# icrawledtv
## description
i-crawl-edtv

教育テレビの実況からキャプチャを探して貯めこんでおきます。
貯めこんだURLをTumblrにポストします。あっという間にアップロード制限に引っかかります。

## preparation
+ ./tokens.yaml
	+ Tumblrの認証用のキーを記述しておきます
+ ./subbacks.yaml
	+ スレッド一覧のULRとtvの名前のHashを配列形式で記述しておきます
+ ./db/links.db
	+ ./db以下のマイグレーションファイルを実行して生成しておきます

## usage
	ruby ./edtv_crawler.rb
	ruby ./tumblr_poster.rb
