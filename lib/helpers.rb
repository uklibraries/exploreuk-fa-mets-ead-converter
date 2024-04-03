#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

FA_MAX_LENGTH = 1000
FA_AEON_MAX = 80

CPATH_SHORT = 'c|c01|c02|c03|c04|c05|c06|c07|c08|c09|c10|c11|c12'
CPATH = 'xmlns:c|xmlns:c01|xmlns:c02|xmlns:c03|xmlns:c04|xmlns:c05|xmlns:c06|xmlns:c07|xmlns:c08|xmlns:c09|xmlns:c10|xmlns:c11|xmlns:c12'

def get_config
  YAML.load_file(File.join(APPROOT, 'config', 'config.yml'))
end

def xmlnspath(path)
  path.split('/').collect {|step|
    if step =~ /:/ or step.length == 0
      step
    else
      "xmlns:#{step}"
    end
  }.join('/')
end

def fa_render(fragment)
  node = Nokogiri::XML.fragment(fragment)
  # The use of node.child.children is deliberate
  node.child.children.collect {|child|
    case child.name
    when "emph"
      fa_render_title(child)
    when "extref"
      fa_render_extref(child)
    when "title"
      fa_render_title(child)
    else
      child.content
    end
  }.join("")
end

def fa_render_title(node)
  if node.has_attribute?('render')
    case node['render']
    when 'italic'
      '<i>' + node.content + '</i>'
    when 'doublequote'
      '"' + node.content + '"'
    else
      '"' + node.content + '"'
    end
  else
    node.content
  end
end

def fa_render_extref(node)
  if node.has_attribute?('href')
    fa_render_extref_ns(node, "")
  elsif node.has_attribute?('xlink:href')
    fa_render_extref_ns(node, 'xlink')
  else
    node.content
  end
end

def fa_render_extref_ns(node, ns)
  href = 'href'
  show = 'show'

  if ns.length > 0
    href = "#{ns}:href"
    show = "#{ns}:show"
  end

  show_new = true
  if node.has_attribute?(show) and node[show] === 'replace'
    show_new = false
  end

  pieces = [
    '<a href="',
    node[href],
    '"',
  ]
  if show_new
    pieces << ' target="_blank" rel="noopener noreferrer"'
  end
  pieces << '>'
  pieces << node.content
  pieces << '</a>'
  pieces.join("")
end

def fa_brevity(message, maxlen = 0)
  if maxlen == 0
    maxlen = FA_MAX_LENGTH
  end
  if message.length > maxlen
    source_words = message.split(/\b/)
    target_words = []
    current_length = 0
    source_words.each do |word|
      if (current_length == 0) || (current_length + word.length <= maxlen)
        target_words << word
        current_length += word.length + 1
      else
        break
      end
    end
    if target_words.count == 0
      message = '…'
    else
      terminal = target_words.last
      if terminal =~ /^\W+$/
        target_words.pop
      end
      message = target_words.join("") + '…'
    end
  end
  message
end
