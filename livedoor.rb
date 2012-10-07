# -*- coding: utf-8 -*-
require "rubygems"
require "bundler/setup"
Bundler.require

a = Mechanize.new {|agent|
  agent.user_agent = 'Mozilla/5.0 (compatible; MSIE 9.0; Windows Phone OS 7.5; Trident/5.0; IEMobile/9.0; FujitsuToshibaMobileCommun; IS12T; KDDI)'
}

a.get("https://member.livedoor.com/login/") {|page|
  form = page.form_with(name: "loginForm")
  form.livedoor_id = "mastertest"
  form.password = "jlMcbgtacIPs"
  page2 = form.submit
  cms_page =  page2.link_with(href: /r\/user_blogcms/).click
  edit_page = cms_page.link_with(href: /\/blog\/mastertest\/article\/edit/).click
  article_form = edit_page.form_with(name: "ArticleForm")
  # 隠されたtextareaにpreview部分, 続きを読む(ここまでで公開記事全体), プライベートの3つに分けて登録
  article_form.title = "そのにてきなたいとるだよ"
  article_form.body = "<p>きじbody</p> <hr /> \n へいへい"
  article_form.body_more = "もっとよむとaaaaaaaaaaaaaaaaaaaaこ"
  article_form.body_private = ""

  # 記事投稿
  article_form.submit
}



