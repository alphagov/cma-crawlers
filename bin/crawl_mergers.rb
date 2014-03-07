#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'anemone'
require 'cma/oft/mergers/case_list'

CASE_INDEX        = %r{/OFTwork/mergers/Mergers_Cases/?$}
CASE              = %r{/OFTwork/mergers/Mergers_Cases/20[0-9]{2}/[a-z|A-Z|0-9]+}
CASE_UNDERTAKINGS = %r{/OFTwork/mergers/register/Initial-undertakings}
CASE_DECISION     = %r{/OFTwork/mergers/decisions/20[0-9]{2}/[a-z|A-Z|0-9]+}
ASSET             = %r{\.pdf$}

def create_or_update_content_for(page)
  case page.url.to_s
  when CASE_INDEX
    CMA::OFT::Mergers::CaseList.from_html(page.doc).save!
  when CASE
    puts "#{page.url.path} parse case"
  when CASE_UNDERTAKINGS
    puts "#{page.url.path} parse undertakings"
  when CASE_DECISION
    puts "#{page.url.path} parse decision"
  when ASSET
    puts "#{page.url.path} handle asset"
  else
    puts "*** WARN: skipping #{page.url}"
  end
end

Anemone.crawl('http://oft.gov.uk/OFTwork/mergers/Mergers_Cases') do |crawl|
  MERGERS_INDEX_PAGES  = %r{/OFTwork/mergers/Mergers_Cases/20[0-9]{2}/?$}
  MERGERS_FILTER_PAGES = %r{\?caseByCompany=}
  MERGERS_FTA          = %r{mergers_fta}
  MAILTO_LINKS         = %r{mailto:}
  IN_PAGE_ANCHORS      = %r{/?#}

  SKIP_LINKS_LIKE = [
    MERGERS_INDEX_PAGES,
    MERGERS_FILTER_PAGES,
    MERGERS_FTA,
    MAILTO_LINKS,
    IN_PAGE_ANCHORS
  ]

  crawl.on_every_page do |page|
    create_or_update_content_for(page)
  end

  crawl.focus_crawl do |page|
    next [] if page.doc.nil?

    page.doc.css('.body-copy a').map do |a|
      next unless (href = a['href'])

      unless SKIP_LINKS_LIKE.any? { |pattern| pattern =~ href }
        URI(File.join('http://oft.gov.uk', a['href']))
      end
    end.compact
  end
end
