class RssContents
  require 'open-uri'
  require 'nokogiri'

  # 情報取得元のホスト名
  TARGET_HOST = 'http://www.city.isehara.kanagawa.jp'
  # 情報取得元のパス
  TARGET_PATH = '/topics.htm'
  # 指定秒数以下かのチェックで使用する秒数を指定
  SPECIFIED_TIME = 3600
  # 詳細ページの取得件数
  NUMBER_OF_DETAIL = 5

  @result_cache = []
  @last_update = Time.now

  class << self
    # rss用情報の@result_cacheを更新する
    # @return [Array-of_Hash]
    # @note 指定時間が経過していれば情報取得元をつついてしまうので、
    #       表示の際には.result_cacheを使用するようにする。
    # @note 別途cronなどで/rss_reloadingにアクセスすることでキャッシュしておくこと。
    def rebuild_contents
      # 毎回TARGET_HOSTを突かないようにする
      return @result_cache if use_result_of_previous?

      @last_update, contents = Time.now, []
      contents_of_update_history_page.each_with_index do |item, order|
        contents << RssContents.new(item[:element], item[:date], order)
      end
      @result_cache = contents
    end

    # クラスインスタンス変数の@result_cacheを返す
    # @result_cacheがempty?の場合はreloading_contentsを実行
    # @return [Array] #<RssContents>
    def result_cache
      rebuild_contents if @result_cache.empty?
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
    #   [{ id: 1, date: '2014-09-26', content: #<Nokogiri::XML::Element> },
    #    { id: 2, date: '2014-09-26', content: #<Nokogiri::XML::Element> },
    #    ..]
    def contents_of_update_history_page # rubocop:disable Metrics/MethodLength
      doc = Nokogiri::HTML(open("#{TARGET_HOST}#{TARGET_PATH}"))
      result, temp_date_string = [], nil

      doc.css('.contentsArea h1 ~ *')
        .css('p', 'li').each_with_index do |element, i|
        if element.name == 'p' && /\d{1,2}.\d{1,2}./.match(element.text)
          temp_date_string = build_date_string(element.text)
        elsif element.name == 'li'
          result << { id: i, date: temp_date_string, element: element }
        end
      end
      result
    end

    def build_date_string(s)
      match_data = /(\d{1,2})月(\d{1,2})日/.match(s)
      mm, dd = *match_data[1..2]
      Time.new(Time.new.year, mm, dd).strftime('%Y-%m-%d')
    end

    # 前回処理時間から指定時間以下かつ、@result_cacheが空でない場合はtrue
    # @return [Boolean]
    def use_result_of_previous?
      SPECIFIED_TIME > (Time.now - @last_update) && !@result_cache.empty?
    end
  end

  attr_reader :title, :link, :description, :date, :order

  def initialize(element, date, order)
    @title       = element.text
    @link        = link_to_detail(element)
    @description = description_data(order)
    @date        = date
    @order       = order
  end

  def to_hash
    { title:       @title,
      link:        @link,
      description: @description,
      date:        @date,
      order:       @order }
  end

  private

  # 渡されたNokogiri::XML::Elementからアンカータグを検索し
  # href属性から詳細ページへのリンクを生成する。
  # @return [String, Nil] アンカータグがない場合はnil
  def link_to_detail(element)
    a_tag = element.css('a').first
    a_tag.nil? ? nil : "#{TARGET_HOST}#{a_tag['href']}"
  end

  def description_data(order)
    order < NUMBER_OF_DETAIL ? detail_content(@link) : nil
  end

  # 更新履歴のリンク情報から詳細ページの情報を取得する
  # @param [String] link 詳細ページのURL
  # @return [String, Nil] linkがnilの場合はnil
  def detail_content(link)
    return nil if link.nil?
    doc = Nokogiri::HTML(open(link))
    doc.css('.skip ~ *').map { |v| "<p>#{v.text}</p>" }.join
  end
end
