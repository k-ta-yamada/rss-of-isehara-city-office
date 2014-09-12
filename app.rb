require 'sinatra'
require 'slim'
require './lib/rss_contents'

# このサイト
THIS_SITE = 'http://rss-of-the-city-hall.herokuapp.com'

if development?
  require 'sinatra/reloader'
  require 'pry'
  require 'byebug'
end

get '/' do
  slim :index,
       locals: { nodes: RssContents.data_for_rss,
                 last_update: RssContents.instance_variable_get(:@last_update) }
end

get '/rss' do
  rss = RSS::Maker.make('2.0') do |maker|
    maker.channel.about = "#{THIS_SITE}/rss"
    maker.channel.title = '市役所公式HPの更新履歴'
    maker.channel.description = '市役所公式HPの更新履歴をRSSにしたもの'
    maker.channel.link = THIS_SITE

    RssContents.data_for_rss.each do |h|
      next if h[:link].nil?
      item = maker.items.new_item
      item.title = h[:title]
      item.link = h[:link]
      item.description = h[:description]
    end
  end

  rss.to_s
end
