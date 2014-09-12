# RSS用の情報取得などを行うクラス
class RssContents
  require 'open-uri'
  require 'nokogiri'
  require 'rss'

  # 情報取得元サイト
  TARGET_SITE = 'http://www.city.isehara.kanagawa.jp'
  # 情報取得元サイトのURL
  TARGET_URL = "#{TARGET_SITE}/topics.htm"
  # 指定秒数以内かのチェックで使用する秒数を指定
  SPECIFIED_TIME = 600

  @result = []
  @last_update = Time.now

  class << self
    # 取得情報をHashのArrayで返す
    # @return [Array of Hash]
    def data_for_rss
      # 毎回TARGET_SITEを突かないようにするため
      # 前回処理時間から指定時間以内かつ、@resultが空でない場合はreturn
      return @result if within_specified_time? && !@result.empty?

      @result = []
      contents_of_update_history_page.each do |elm|
        title = elm.text
        link = elm.css('a').first.nil? ? nil : url_of_detail_contents(elm)
        description = link.nil? ? nil : contents_of_detail_page(link)
        @result << { title: title, link: link, description: description }
      end
      @last_update = Time.now
      @result
    end

    # rubocop:disable Style/TrivialAccessors
    # attr_readerへの変更を警告されるが、クラスインスタンス変数を使用したいため
    def last_update_time
      @last_update
    end
    # rubocop:enable Style/TrivialAccessors

    private

    # 前回実行時間から指定の秒数以内かどうかを返す
    # @return
    #   true  : 指定時間以内
    #   false : 指定時間以上
    def within_specified_time?
      SPECIFIED_TIME > (Time.now - @last_update)
    end

    # 更新履歴ページから一覧を取得する
    # @return [Array]
    def contents_of_update_history_page
      doc = Nokogiri::HTML(open(TARGET_URL))
      doc.css('.contentsArea li')
    end

    # 詳細ページのURLを生成する
    # @param [Nokogiri::XML::Element] elm
    # @return [String]
    def url_of_detail_contents(elm)
      "#{TARGET_SITE}#{elm.css('a').first['href']}"
    end

    # 更新履歴のリンク情報から詳細ページの情報を取得する
    # @param [String] link 詳細ページのURL
    # @return [String]
    def contents_of_detail_page(link)
      doc = Nokogiri::HTML(open(link))
      doc.css('.skip ~ *').map { |elm| elm.text }.join("\n")
    end
  end
end
