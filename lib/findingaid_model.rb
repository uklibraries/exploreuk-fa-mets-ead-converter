#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "nokogiri"
require "pairtree"
require "uri"

# sets $mets_content_links

class FindingaidModel
  def initialize(dip, config)
    @dip = dip
    @config = config
    @id = File.basename(dip.path) # pass as argument?
    initialize_mets
    preanalyze_mets
    initialize_ead
    @model = {}
  end

  def initialize_mets
    @mets_namespaces = {
      "mets" => "http://www.loc.gov/METS/",
    }
    metsfile = File.join(@dip.path, @dip['data/mets.xml'])
    unless File.exist? metsfile and File.file? metsfile
      raise Errno::ENOENT
    end
    @mets = Nokogiri::XML(IO.read metsfile)
  end

  def initialize_ead
    @ead_namespaces = {
      "xmlns" => "urn:isbn:1-93166-22-9",
      "xmlns:xlink" => "http://www.w3.org/1999/xlink",
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
    }
    @eadhref = File.join('data', @mets.xpath('//mets:file[@ID="AccessFindingAid"]/mets:FLocat', @mets_namespaces).first['xlink:href'])
    eadfile = File.join(@dip.path, @dip[@eadhref])
    unless File.exist? eadfile and File.file? eadfile
      raise Errno::ENOENT
    end
    @ead = Nokogiri::XML(IO.read eadfile)
    if @ead.root.attributes.count == 0
      @ead_namespaces.each do |ns, uri|
        @ead.root[ns] = uri
        @ead = Nokogiri::XML(@ead.to_xml)
      end
    end
  end

  def preanalyze_mets
    @file_hash = {}
    @mets.xpath('//mets:file[@USE="thumbnail" or @USE="reference image"]', @mets_namespaces).each do |file|
      id = file['ID']
      flocat = file.xpath('mets:FLocat', @mets_namespaces).first
      @file_hash[id] = {
        id: id,
        use: file['USE'],
        mimetype: file['MIMETYPE'],
        href: flocat['xlink:href'],
      }
    end
    $mets_content_links = {}
    @mets.xpath('//mets:structMap/mets:div', @mets_namespaces).each do |section|
      section.xpath('mets:div').each do |page|
        first_page_id = [@id, section['ORDER'], '1'].join('_')
        item_id = [@id, section['ORDER'], page['ORDER']].join('_')
        links = []
        page.xpath('mets:fptr').each do |fptr|
          if @file_hash.has_key?(fptr['FILEID'])
            fh = @file_hash[fptr['FILEID']]
            fh[:id] = item_id + "_" + fh[:use].gsub(/\s+/, '_')
            links << fh
          end
        end
        if links.count > 0
          $mets_content_links[first_page_id] ||= []
          $mets_content_links[first_page_id] << links
        end
      end
    end
  end

  def process
    @model = {
      header: {
        abstract: collect_ead('//archdesc/did/abstract'),
        descriptive_summary: {
          title: collect_ead('//archdesc/did/unittitle'),
          date: collect_ead('//archdesc/did/unitdate'),
          creator: collect_ead('//archdesc/did/origination/persname'),
          extent: collect_ead('//archdesc/did/physdesc/extent'),
          subjects: collect_ead('//archdesc/controlaccess/subject'),
          arrangement: collect_ead('//archdesc/arrangement/p'),
          finding_aid_author: collect_ead('//filedesc/titlestmt/author'),
          preferred_citation: collect_ead('//archdesc/prefercite/p'),
        },
        collection_overview: {
          biography_history: collect_ead('//archdesc/bioghist/p'),
          scope_and_content: collect_ead('//archdesc/scopecontent/p'),
          processing_info: collect_ead('//archdesc/processinfo/p'),
        },
        restrictions_on_access_and_use: {
          conditions_governing_access: collect_ead('//archdesc/accessrestrict/p'),
          use_restrictions: collect_ead('//archdesc/userestrict/p'),
        },
        special_links: {
          ead: [
            @config["dip_url_prefix"],
            @id,
            @eadhref,
          ].join("/"),
          more_from_this_collection: more_from_this_collection,
        }
      },
    }

    # contents
    dsc = @ead.xpath('//xmlns:dsc').first
    unless dsc.nil?
      @model[:contents_of_the_collection] = components(dsc)
    end
  end

  def more_from_this_collection
    source = @mets.xpath('//source').first
    if source.nil?
      source = collect_ead('//archdesc/did/unittitle', render: false)
    end
    "#{@config["search_url_prefix"]}/?f[source_s][]=#{URI.encode_www_form_component(source)}"
  end

  def components(node)
    node.xpath(CPATH).collect do |component|
      Component.new(component).metadata
    end
  end

  def collect_ead(path, **options)
    path = xmlnspath(path)
    if options[:render]
      @ead.xpath(path).collect {|node| fa_render(node)}
    else
      @ead.xpath(path).collect(&:content).join(" ")
    end
  end

  def to_json
    @model.to_json
  end
end
