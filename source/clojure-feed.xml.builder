xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  xml.title "Korny's Blog"
  xml.subtitle "Korny's Blog - clojure"
  xml.id "http://blog.korny.info"
  xml.link "href" => "http://blog.korny.info"
  xml.link "href" => "http://blog.korny.info/clojure-feed.xml", "rel" => "self"
  xml.updated blog.articles.first.date.to_time.iso8601
  xml.author { xml.name "Kornelis Sietsma" }
  blog.articles[0..10].each do |article|
    if article.tags.include? "clojure"
      xml.entry do
        xml.title article.title
        xml.link "rel" => "alternate", "href" => article.url
        xml.id article.url
        xml.published article.date.to_time.iso8601
        xml.updated article.date.to_time.iso8601
        xml.author { xml.name "Kornelis Sietsma" }
        xml.summary article.summary, "type" => "html"
        xml.content article.body, "type" => "html"
      end
    end
  end
end