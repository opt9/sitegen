
import Plugin from require "sitegen.plugin"

html = require "sitegen.html"
date = require "date"
cosmo = require "cosmo"

import copy, bind_methods from require "moon"
import insert from table

FeedPlugin = require "sitegen.plugins.feed"

cmp = {
  date: (dir="desc") ->
    (a, b) ->
      if dir == "asc"
        date(a) < date(b)
      else
        date(a) > date(b)
}

class BlogPlugin extends Plugin
  new: (@site) =>

  write: =>
    @posts = @site\query_pages { is_a: "blog_post" }, sort: (p1, p2) ->
      cmp.date! p1.meta.date, p2.meta.date

    return unless @posts[1]

    @site.logger\plain "blog posts:", #@posts

    import title, url, description from @site.user_vars

    feed_posts = for page in *@posts
      meta = page.meta

      print "*", meta.title, meta.date
      {
        title: meta.title
        date: meta.date
        link: page\url_for true

        -- to avoid getting description of page from chained meta
        description: rawget meta, "description"
      }

    rss_text = FeedPlugin.render_feed {
      :title, :description, link: url
      unpack feed_posts
    }

    @site\write_file "feed.xml", rss_text
