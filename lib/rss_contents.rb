class RssContents
  require 'open-uri'
  require 'nokogiri'
  require 'rss'

  # 情報取得元のホスト名
  TARGET_HOST = 'http://www.city.isehara.kanagawa.jp'
  # 情報取得元のパス
  TARGET_PATH = '/topics.htm'
  # 指定秒数以下かのチェックで使用する秒数を指定
  SPECIFIED_TIME = 3600

  @result_cache = []
  @last_update = Time.now

  class << self
    # 取得情報をHashのArrayで返す
    # @return [Array-of-Hash]
    # @note 指定時間が経過していれば情報取得元をつついてしまうので、
    #       表示の際には.result_cacheを使用するようにする。
    # @note 別途cronなどで/rss_reloadingにアクセスすることでキャッシュしておくこと。
    def reloading_contents
      # 毎回TARGET_HOSTを突かないようにするため
      return @result_cache if use_result_of_previous?

      @result_cache = []
      contents_of_update_history_page.each_with_index do |h, ind|
        h[1].each_with_index do |list_item, order|
          title       = list_item.text
          link        = link_to_detail_page(list_item)
          description = (ind < 1) ? contents_of_detail_page(link) : nil
          @result_cache << { title:       title,
                             link:        link,
                             description: description,
                             date:        h[0],
                             order:       order }
        end
      end
      @last_update = Time.now
    end

    # クラスインスタンス変数の@result_cacheを返す
    # @result_cacheがnilの場合はreloading_contentsを実行
    # @return [Array-of-Hash]
    # @note rubocopでattr_readerへの変更を警告されるが
    #       クラスインスタンス変数を使用したいためにわざとやってる
    def result_cache   # rubocop:disable Style/TrivialAccessors
      reloading_contents if @result_cache.empty?
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

    # 更新履歴ページから一覧を取得し、
    # 日付文字列をkey、liタグのArrayをvalueとするHashを返す
    # @return [Hash]
    # @example
    #   { '2014/09/26' => [Nokogiri::XML::Element, ..],
    #     '2014/09/20' => [Nokogiri::XML::Element, ..],
    #     '2014/09/16' => [Nokogiri::XML::Element, ..] }
    def contents_of_update_history_page
      doc = Nokogiri::HTML(open("#{TARGET_HOST}#{TARGET_PATH}"))
      result, temp_date_string = {}, nil

      doc.css('.contentsArea h1 ~ *').each do |element|
        if element.name == 'p' && /\d{1,2}.\d{1,2}./.match(element.text)
          temp_date_string = build_date_string(element.text)
        elsif element.name == 'ul'
          result[temp_date_string] = element.css('li')
        end
      end
      result
    end

    def build_date_string(s)
      match_data = /(\d{1,2})月(\d{1,2})日/.match(s)
      mm, dd = *match_data[1..2]
      Time.new(Time.new.year, mm, dd).strftime('%Y-%m-%d')
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
      doc.css('.skip ~ *').map { |v| "<p>#{v.text}</p>" }.join
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
