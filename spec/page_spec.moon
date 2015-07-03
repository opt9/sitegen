Site = require "sitegen.site"

import Page from require "sitegen.page"
import SiteFile from require "sitegen.site_file"

query = require "sitegen.query"

describe "page", ->
  create_page = (t={}) ->
    t.meta or= {}
    t.source or= "some_page.md"
    t.target or= "www/some_page.html"
    t.render_fn or= ->
    setmetatable t, Page

  describe "with site & pages", ->
    local site
    before_each ->
      site = Site SiteFile {
        rel_path: "."
      }

      site.pages = {
        create_page {
          meta: {
            is_a: {"blog_post", "article"}
          }
        }
        create_page {
          meta: {
            is_a: "article"
            tags: {"cool"}
          }
        }
        create_page { }
      }

    it "queries with empty result", ->
      pages = site\query_pages { tag: "hello" }
      assert.same {}, pages

    it "queries all with empty query", ->
      pages = site\query_pages { }
      assert.same 3, #pages

    it "queries raw", ->
      pages = site\query_pages { is_a: "article" }
      assert.same 1, #pages

    it "queries filter contains", ->
      pages = site\query_pages { is_a: query.filter.contains "article" }
      assert.same 2, #pages

    it "queries filter contains", ->
      pages = site\query_pages { tags: query.filter.contains "cool" }
      assert.same 1, #pages