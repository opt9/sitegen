local Plugin
Plugin = require("sitegen.plugin").Plugin
local slugify
slugify = require("sitegen.common").slugify
local insert
insert = table.insert
local IndexerPlugin
do
  local _class_0
  local _parent_0 = Plugin
  local _base_0 = {
    tpl_helpers = {
      "index"
    },
    events = {
      ["page.content_rendered"] = function(self, e, page, content)
        if self.current_index[page] then
          return 
        end
        if not (page.meta.index) then
          return 
        end
        local body
        body, self.current_index[page] = self:parse_headers(content, page.meta.index)
        return page:set_content(body)
      end
    },
    index_for_page = function(self, page)
      page:render()
      return self.current_index[page]
    end,
    index = function(self, page, arg)
      if page.meta.index == false then
        return ""
      end
      if not (self.current_index[page]) then
        assert(page.tpl_scope.render_source, "attempting to render index with no body available (are you in cosmo?)")
        arg = arg or { }
        setmetatable(arg, {
          __index = page.meta.index
        })
        local body
        body, self.current_index[page] = self:parse_headers(page.tpl_scope.render_source, arg)
        coroutine.yield(body)
      end
      return self:render_index(self.current_index[page])
    end,
    parse_headers = function(self, content, opts)
      if not (type(opts) == "table") then
        opts = { }
      end
      local min_depth = opts.min_depth or 1
      local max_depth = opts.max_depth or 9
      local link_headers = opts.link_headers
      local _slugify = opts.slugify or function(h)
        return slugify(h.title)
      end
      local headers = { }
      local current = headers
      local push_header
      push_header = function(i, header)
        i = tonumber(i)
        if not current.depth then
          current.depth = i
        else
          if i > current.depth then
            current = {
              parent = current,
              depth = i
            }
          else
            while i < current.depth and current.parent do
              insert(current.parent, current)
              current = current.parent
            end
            if i < current.depth then
              current.depth = i
            end
          end
        end
        return insert(current, header)
      end
      local replace_html
      replace_html = require("web_sanitize.query.scan_html").replace_html
      local out = replace_html(content, function(stack)
        local el = stack:current()
        local depth = el.tag:match("h(%d+)")
        if not (depth) then
          return 
        end
        depth = tonumber(depth)
        if not (depth >= min_depth and depth <= max_depth) then
          return 
        end
        local header = {
          title = el:inner_text(),
          html_content = el:inner_html()
        }
        header.slug = _slugify(header)
        push_header(depth, header)
        if current.parent then
          local last_parent = current.parent[#current.parent]
          header.slug = tostring(last_parent.slug) .. "/" .. tostring(header.slug)
        end
        if link_headers then
          local html = require("sitegen.html")
          return el:replace_inner_html(html.build(function()
            return a({
              name = header.slug,
              href = "#" .. tostring(header.slug),
              raw(header.html_content)
            })
          end))
        else
          return el:replace_attributes({
            id = header.slug
          })
        end
      end)
      while current.parent do
        insert(current.parent, current)
        current = current.parent
      end
      return out, headers
    end,
    render_index = function(self, headers)
      local html = require("sitegen.html")
      return html.build(function()
        local render
        render = function(headers)
          return ul((function()
            local _accum_0 = { }
            local _len_0 = 1
            for _index_0 = 1, #headers do
              local item = headers[_index_0]
              if item.depth then
                _accum_0[_len_0] = render(item)
              else
                local title, slug, html_content
                title, slug, html_content = item.title, item.slug, item.html_content
                _accum_0[_len_0] = li({
                  a({
                    href = "#" .. tostring(slug),
                    raw(html_content)
                  })
                })
              end
              _len_0 = _len_0 + 1
            end
            return _accum_0
          end)())
        end
        return render(headers)
      end)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, site)
      self.site = site
      _class_0.__parent.__init(self, self.site)
      self.current_index = { }
    end,
    __base = _base_0,
    __name = "IndexerPlugin",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  IndexerPlugin = _class_0
  return _class_0
end
