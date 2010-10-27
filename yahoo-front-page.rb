#!/usr/bin/ruby

require 'uri'
require 'net/http'
require 'rss/maker'
require 'json'

require 'rubygems'
require 'nokogiri'

def fetch url
  Net::HTTP.get_response( URI.parse(url) ).body
end

main = fetch 'http://www.yahoo.com'
main =~ /"pkgIds":(\[.*?\])/ or raise "No pkgIds"

packages = JSON.parse $1

def get_story story_id
  crap = '{"reqs":[{"handler":"cfg.maple_dali.handler.refresh","data":{"maple":{"module":"p_13872472","ba":{"_txnid":0,"_mode":"json","_id":"p_13872472","_container":0,"_action":"show","_subAction":"story","storyId":"id-46370","storyIndex":15,"cokeTestId":"","todaytop":"1"}}},"txId":13}],"props":{"dali":{"crumb":"vhysjW/uLam","yuid":"","loggedIn":"0","mLogin":0}}}'
  post = JSON.parse(crap)
  post["reqs"][0]["data"]["maple"]["ba"]["storyId"] = story_id
  url = "http://www.yahoo.com/js?__r=1288162468190&post=" + URI.escape(post.to_json)

  res = fetch url
  res = JSON.parse(res)

  data = res["resps"][0]["data"]["mods"][0]["data"]
end

rss = RSS::Maker.make "2.0" do |m|
  m.channel.title = "Yahoo Front Page"
  m.channel.link = "http://www.yahoo.com"
  m.channel.description = "Yahooligans"
  m.items.do_sort = true

  packages.each do |story_id|
    data = get_story story_id

    doc = Nokogiri::HTML( data["story"] )
    doc.css('h2').first.remove

    image = doc.css('img').first
    image["src"] = data["headerImageSrc"]
    image["alt"] = data["headerImageAlt"]

    title = doc.css('h3 a').first
    title.remove

    i = m.items.new_item
    i.title = title.content
    i.link = title[:href]
    i.date = Time.now

    i.guid.content = 'http://rss.yahoo.com/' + story_id
    i.guid.isPermaLink = false
    i.description = doc.to_s
  end
end

puts rss.to_s
