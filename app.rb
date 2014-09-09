require 'sinatra'
require 'slim'
require 'open-uri'
require 'nokogiri'
require 'rss'

if development?
  require 'sinatra/reloader'
  require 'pry'
  require 'byebug'
end

TARGET_SITE = 'http://www.city.isehara.kanagawa.jp'
TARGET_URL = "#{TARGET_SITE}/topics.htm"
THIS_SITE = 'http://rss-of-the-city-hall.herokuapp.com/'

get '/' do
  slim :index, locals: { nodes: ary_of_hash_for_rss(contents_of_update_history_page) }
end

get '/rss' do
  rss = RSS::Maker.make('2.0') do |maker|
    maker.channel.about = "#{THIS_SITE}/rss"
    maker.channel.title = '市役所公式HPの更新履歴'
    maker.channel.description = '市役所公式HPの更新履歴をRSSにしたもの'
    maker.channel.link = THIS_SITE

    ary_of_hash_for_rss(contents_of_update_history_page).each do |h|
      next if h[:link].nil?
      item = maker.items.new_item
      item.title = h[:title]
      item.link = h[:link]
      item.description = h[:description]
    end
  end

  rss.to_s
end

def contents_of_update_history_page
  doc = Nokogiri::HTML(open(TARGET_URL))
  doc.css('.contentsArea li')
end

def contents_of_link_page(link)
  doc = Nokogiri::HTML(open(link))
  doc.css('.skip ~ *').map { |elm| elm.text }.join("\n")
end

def ary_of_hash_for_rss(nodes)
  result = []
  nodes.each do |elm|
    title = elm.text
    link = elm.css('a').first.nil? ? nil : "#{TARGET_SITE}#{elm.css('a').first['href']}"
    description = link.nil? ? nil : contents_of_link_page(link)
    result << { title: title, link: link, description: description }
  end
  result
end
