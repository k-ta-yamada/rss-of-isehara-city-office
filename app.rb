require 'sinatra'
require 'sinatra/json'
require 'rss'
require 'slim'
if development?
  require 'sinatra/reloader'
  require 'pry'
  require 'byebug'
end
configure :production do
  require 'newrelic_rpm'
end
require './lib/rss_contents'

# このサイト
THIS_SITE = 'http://rss-of-isehara-city-office.herokuapp.com'

get '/' do
  slim :index,
       locals: { nodes: RssContents.result_cache,
                 last_update: RssContents.last_update }
end

get '/rss' do
  rss = RSS::Maker.make('2.0') do |maker|
    maker.channel.about       = "#{THIS_SITE}/rss"
    maker.channel.title       = '伊勢原市役所公式HPの更新履歴'
    maker.channel.link        = THIS_SITE
    maker.channel.description = '伊勢原市役所公式HPの更新履歴をRSSにしたもの'

    RssContents.result_cache.each do |content|
      next if content.link.nil?
      item = maker.items.new_item
      item.title       = content.title
      item.link        = content.link
      item.description = content.description
    end
  end

  rss.to_s
end

get '/rss.json' do
  json(rss: RssContents.result_cache.map(&:to_hash))
end

get '/rss_reloading' do
  RssContents.rebuild_contents
  "reloaded contents at #{RssContents.last_update}"
end
