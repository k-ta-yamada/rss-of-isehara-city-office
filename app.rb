require 'sinatra'
require 'open-uri'
require 'nokogiri'
require 'rss'

if development?
  require 'sinatra/reloader'
  require 'pry'
end

TARGET_URL = 'http://www.city.isehara.kanagawa.jp/topics.htm'

get '/' do
  erb :index, locals: { nodes: ary_of_hash_for_rss(get_resource_node) }
end

get '/rss' do
  rss = RSS::Maker.make('2.0') do |maker|
    maker.channel.about = 'http://rss-of-the-city-hall.herokuapp.com/'
    maker.channel.title = '市役所公式HPの更新履歴'
    maker.channel.description = '市役所公式HPの更新履歴をRSSにしたもの'
    maker.channel.link = 'http://rss-of-the-city-hall.herokuapp.com/'

    ary_of_hash_for_rss(get_resource_node).each do |h|
      item = maker.items.new_item
      item.title = h[:title]
      item.link = h[:link]
    end

  end

  rss.to_s
end

def get_resource_node
  html = open(TARGET_URL).read
  doc = Nokogiri::HTML(html)
  node = doc.css('.contentsArea li')
  node
end

def ary_of_hash_for_rss(node)
  result = []
  node.each do |elm|
    title = elm.text
    link = "http://www.city.isehara.kanagawa.jp/#{elm.css('a').first['href']}"
    result << { title: title, link: link }
  end
  result
end
