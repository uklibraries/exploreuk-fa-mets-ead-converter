#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'nokogiri'

class Component
  def initialize(node)
    @node = node
    @md5 = Digest::MD5.new
    @title = nil
  end

  def metadata
    m = {
      id: @node['id'],
      level: @node['level'],
      title: title,
    }
    m[:biography_history] = collect_ead(@node, 'bioghist/p')
    m[:scope_and_content] = collect_ead(@node, 'scopecontent/p')
    m[:processing_info] = collect_ead(@node, 'processinfo/p')

    m[:links] = get_content_links

    cl = container_lists
    if cl.count > 0
      m[:container_lists] = cl
    end
    sc = subcomponents
    if sc.count > 0
      m[:subcomponents] = sc
    end
    m
  end

  def get_content_links
    path = xmlnspath('did/dao')
    @node.xpath(path).collect {|dao|
      first_page_id = dao['entityref']
      if $mets_content_links.has_key? first_page_id
        $mets_content_links[first_page_id]
      end
    }
  end

  def subcomponents
    if @node.xpath(CPATH).first.nil?
      []
    else
      @node.xpath(CPATH).collect do |component|
        Component.new(component).metadata
      end
    end
  end

  def title
    if @title.nil?
      pieces = @node.xpath(xmlnspath("did/unittitle")) + @node.xpath(xmlnspath("did/unitdate"))
      @title = pieces.collect {|piece| fa_render(piece)}.select {|piece| piece.length > 0}.join(', ')
    end
    @title
  end

  def container_lists
    cl = []
    aspects = []
    buckets = []
    section = {}
    section_ids = []

    @node.xpath('xmlns:did/xmlns:container').each do |container|
      aspect = {
        type: container_type(container),
        content: container.content,
      }

      if container.has_attribute?('id')
        id = container['id'].strip
      else
        id = @md5.hexdigest(container.to_xml)
      end
      aspect[:id] = id

      if container.has_attribute?('parent')
        id = container['parent'].strip
        aspect[:id] = id
        section[id] ||= []
        section[id] << aspect.dup
      else
        section[id] ||= [aspect]
        section_ids << id
      end
    end

    section_ids.each do |id|
      buckets << section[id].dup
    end

    if buckets.count > 0
      buckets.each do |bucket|
        request_target = "fa-request-target-" + @md5.hexdigest(bucket.to_json)
        container_list_pieces = []
        first = true
        bucket.each do |aspect|
          piece = aspect[:type] + ' ' + aspect[:content]
          if first
            piece.capitalize!
            first = false
          end
          container_list_pieces << piece
        end
        volume = container_list_pieces.first
        summary = container_list_pieces.join(', ')
        full_container_list = fa_brevity(summary + ': ' + title, FA_AEON_MAX)
        container_list_pieces.shift
        rest = container_list_pieces.join(', ')
        container_list = {
          id: request_target,
          summary: summary,
          volume: volume,
          container: rest,
          container_list: full_container_list,
        }

        cl << container_list.dup
      end
    end

    cl
  end

  def container_type(container)
    if container.has_attribute?('type')
      type = container['type'].strip
      if type === 'othertype'
        if container.has_attribute?('label')
          container['label'].strip
        else
          'container'
        end
      else
        type
      end
    elsif container.has_attribute?('label')
      container['label'].strip
    else
      'container'
    end
  end

  def collect_ead(node, path)
    path = xmlnspath(path)
    node.xpath(path).collect {|target| fa_render(target)}
  end
end
