# これは何？

[伊勢原市役所の公式ホームページ](http://www.city.isehara.kanagawa.jp)
の更新履歴ページを
[Nokogiri](http://nokogiri.org/)でギコギコして
[標準ライブラリのrss](http://docs.ruby-lang.org/ja/2.1.0/library/rss.html)でRSSを生成する。

情報の取得はHeroku Schedulerを使用して1日1回取得（08:30 UTC）

更にNew RelicのAvailability monitoringでリロード用ページを監視し、
アプリ側では一時間経過後に再取得するようにしているので、
ほぼ1時間に1回のペースで取得。


# サンプル
[http://rss-of-isehara-city-office.herokuapp.com](http://rss-of-isehara-city-office.herokuapp.com)
