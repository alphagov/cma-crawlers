# -*- coding: utf-8 -*-
#
#--
# HASTILY-PATCHED VERSION TO FORCE INLINE LINKS
# Copyright (C) 2009-2014 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown which is licensed under the MIT.
#++
#

require 'rexml/parsers/baseparser'

module Kramdown

  module Converter

    # Converts an element tree to the kramdown format.
    class Kramdown < Base

      def convert_a(el, opts)
        if el.attr['href'].empty?
          "[#{inner(el, opts)}]()"
        else # entire footnote style removed
          title = el.attr['title'].to_s.empty? ? '' : ' "' + el.attr['title'].gsub(/"/, "&quot;") + '"'
          "[#{inner(el, opts)}](#{el.attr['href']}#{title})"
        end
      end
    end
  end
end
