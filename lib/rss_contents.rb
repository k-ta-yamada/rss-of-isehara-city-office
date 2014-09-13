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
    # @return [Array-of-Hash]
    def data_for_rss
      # 毎回TARGET_SITEを突かないようにするため
      return @result if use_result_of_previous?

      @result = []
      contents_of_update_history_page.each do |list_item|
        title       = list_item.text
        link        = link_to_detail_page(list_item)
        description = contents_of_detail_page(link)
        @result << { title: title, link: link, description: description }
      end
      @last_update = Time.now
      @result
    end

    # クラスインスタンス変数の@last_updateを返す
    # @return [Time]
    # @note rubocopでattr_readerへの変更を警告されるが
    #       クラスインスタンス変数を使用したいためにわざとやってる
    def last_update   # rubocop:disable Style/TrivialAccessors
      @last_update
    end

    private

    # 更新履歴ページから一覧を取得する
    # @return [Array]
    def contents_of_update_history_page
      doc = Nokogiri::HTML(open(TARGET_URL))
      doc.css('.contentsArea li')
    end

    # 渡されたNokogiri::XML::Elementからアンカータグを検索し
    # href属性から詳細ページへのリンクを生成する。
    # @return [String, Nil] アンカータグがない場合はnil
    def link_to_detail_page(elm)
      a_tag = elm.css('a').first
      a_tag.nil? ? nil : "#{TARGET_SITE}#{a_tag['href']}"
    end

    # 更新履歴のリンク情報から詳細ページの情報を取得する
    # @param [String] link 詳細ページのURL
    # @return [String, Nil] linkがnilの場合はnil
    def contents_of_detail_page(link)
      return nil if link.nil?
      doc = Nokogiri::HTML(open(link))
      doc.css('.skip ~ *').map { |elm| elm.text }.join("\n")
    end

    # 前回処理時間から指定時間以内かつ、@resultが空でない場合はtrue
    # @return [Boolean]
    def use_result_of_previous?
      within_specified_seconds? && !@result.empty?
    end

    # 前回実行時間から指定の秒数以内かどうかを返す
    # @return [Boolean]
    #   true  : 指定時間以内
    #   false : 指定時間以上
    def within_specified_seconds?
      SPECIFIED_TIME > (Time.now - @last_update)
    end
  end
end
