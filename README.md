# これは何？

とある市役所の公式ホームページの更新履歴ページを
[Nokogiri](http://nokogiri.org/)でギコギコして
[標準ライブラリのrss](http://docs.ruby-lang.org/ja/2.1.0/library/rss.html)でRSSを生成する。

情報の取得はHeroku Schedulerを使用して1日1回取得（08:30 UTC）


# サンプル
[http://rss-of-the-city-hall.herokuapp.com]()
