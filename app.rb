require 'sinatra'
require 'open-uri'
require 'nokogiri'
require 'rss'

if development?
  require 'sinatra/reloader'
  require 'pry'
end

TARGET_SITE = 'http://www.city.isehara.kanagawa.jp'
TARGET_URL = "#{TARGET_SITE}/topics.htm"
THIS_SITE = 'http://rss-of-the-city-hall.herokuapp.com/'

get '/' do
  erb :index, locals: { nodes: ary_of_hash_for_rss(get_resource_node) }
end

get '/rss' do
  rss = RSS::Maker.make('2.0') do |maker|
    maker.channel.about = "#{THIS_SITE}/rss"
    maker.channel.title = '市役所公式HPの更新履歴'
    maker.channel.description = '市役所公式HPの更新履歴をRSSにしたもの'
    maker.channel.link = THIS_SITE

    ary_of_hash_for_rss(get_resource_node).each do |h|
      next if h[:link].nil?
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
    link = elm.css('a').first.nil? ? nil : "#{TARGET_SITE}#{elm.css('a').first['href']}"
    result << { title: title, link: link }
  end
  result
end
