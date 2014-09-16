class RssContents
  require 'open-uri'
  require 'nokogiri'
  require 'rss'

  # 情報取得元のホスト名
  TARGET_HOST = 'http://www.city.isehara.kanagawa.jp'
  # 情報取得元のパス
  TARGET_PATH = '/topics.htm'
  # 指定秒数以下かのチェックで使用する秒数を指定
  SPECIFIED_TIME = 600

  @result_cache = []
  @last_update = Time.now

  class << self
    # 取得情報をHashのArrayで返す
    # @return [Array-of-Hash]
    def data_for_rss
      # 毎回TARGET_HOSTを突かないようにするため
      return @result_cache if use_result_of_previous?

      @result_cache = []
      contents_of_update_history_page.each do |list_item|
        title       = list_item.text
        link        = link_to_detail_page(list_item)
        description = contents_of_detail_page(link)
        @result_cache << { title: title, link: link, description: description }
      end
      @last_update = Time.now
      @result_cache
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
      doc = Nokogiri::HTML(open("#{TARGET_HOST}#{TARGET_PATH}"))
      doc.css('.contentsArea li')
    end

    # 渡されたNokogiri::XML::Elementからアンカータグを検索し
    # href属性から詳細ページへのリンクを生成する。
    # @return [String, Nil] アンカータグがない場合はnil
    def link_to_detail_page(elm)
      a_tag = elm.css('a').first
      a_tag.nil? ? nil : "#{TARGET_HOST}#{a_tag['href']}"
    end

    # 更新履歴のリンク情報から詳細ページの情報を取得する
    # @param [String] link 詳細ページのURL
    # @return [String, Nil] linkがnilの場合はnil
    def contents_of_detail_page(link)
      return nil if link.nil?
      doc = Nokogiri::HTML(open(link))
      doc.css('.skip ~ *').map { |elm| elm.text }.join("\n")
    end

    # 前回処理時間から指定時間以下かつ、@result_cacheが空でない場合はtrue
    # @return [Boolean]
    def use_result_of_previous?
      within_specified_seconds? && !@result_cache.empty?
    end

    # 前回実行時間現在までの秒数が指定の秒数以下かどうかを返す
    # @return [Boolean]
    #   true  : 指定秒数以下
    #   false : 指定秒数以上
    def within_specified_seconds?
      SPECIFIED_TIME > (Time.now - @last_update)
    end
  end
end
