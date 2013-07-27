# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

# A bunch of useful Alfred 2 workflows.
module Pincerna
  # Base class for all filter.
  class Base
    ROOT = File.expand_path(File.dirname(__FILE__) + "/../../")

    # The expression to match.
    MATCHER = /^(?<all>.*)$/i

    # Relevant groups in the match.
    RELEVANT_MATCHES = {
      "all" => ->(_, value) { value }
    }

    # Executes a filtering query.
    #
    # @param type [Symbol] The type of the query.
    # @param query [String] The argument of the query.
    # @return [String] The result of the query.
    def self.execute!(type, query)
      current_dir = File.dirname(__FILE__)

      case type
        when :convert, :unit, :c then
          require current_dir + "/unit_conversion"
          Pincerna::UnitConversion.new(query).filter
        when :currency, :cc then
          require current_dir + "/currency_conversion"
          Pincerna::CurrencyConversion.new(query).filter
        when :translate, :t then
          require current_dir + "/translation"
          Pincerna::Translation.new(query).filter
        when :map, :m then
          require current_dir + "/map"
          Pincerna::Map.new(query).filter
        when :weather, :forecast then
          require current_dir + "/weather"
          Pincerna::Weather.new(query).filter
        when :ip then
          require current_dir + "/ip"
          Pincerna::Ip.new(query).filter
        when :vpn then
          require current_dir + "/vpn"
          Pincerna::Vpn.new(query).filter
        else ""
      end
    end

    # Creates a new query.
    #
    # @param query [String] The argument of the query.
    def initialize(query)
      @query = query.strip
      @cache_dir = File.expand_path("~/Library/Caches/com.runningwithcrayons.Alfred-2/Workflow Data/pincerna") + "/"
      @feedback_items = []
    end

    # Filters a query.
    #
    # @return [String] The feedback items of the query, formatted as XML.
    def filter
      # Match the query
      relevant = self.class::RELEVANT_MATCHES
      matches = self.class::MATCHER.match(@query)

      if matches then
        # Get relevant groups and process them
        args = relevant.collect {|key, value| value.call(self, matches[key]) }

        # Now perform the operation
        results = perform_filtering(*args)

        # Show results if appropriate
        process_results(results).each {|r| add_feedback_item(r) } if results
      end

      output_feedback
    end

    # Filters a query.
    #
    # @param args [Array] The arguments of the query.
    # @return [Array] A list of items to process.
    def perform_filtering(*args)
      raise ArgumentError.new("Must be overriden by subclasses.")
    end

    # Processes items to obtain feedback items.
    #
    # @param results [Array] The items to process.
    # @return [Array] The feedback items.
    def process_results(results)
      raise ArgumentError.new("Must be overriden by subclasses.")
    end

    # Adds a feedback items.
    #
    # @param item [Array] The items to add.
    def add_feedback_item(item)
      @feedback_items << item
    end

    # Outputs the feedback.
    #
    # @return [String] A XML document.
    def output_feedback
      Nokogiri::XML::Builder.new { |xml|
        xml.items do
          @feedback_items.each do |item|
            childs, attributes = split_output_item(item)

            xml.item(attributes) do
              childs.each { |name, value| xml.send(name, value) }
            end
          end
        end
      }.to_xml
    end

    # Converts an array of key-value pairs to an hash.
    #
    # @param array [Array] The array to convert.
    # @return [Hash] The converted hash.
    def array_to_hash(array)
      array.inject({}){ |rv, entry|
        rv[entry[0]] = entry[1]
        rv
      }
    end

    # Rounds a float to a certain precision.
    #
    # @param value [Float] The value to convert.
    # @param precision [Fixnum] The precision to use.
    # @return [Float] The rounded value.
    def round_float(value, precision = 3)
      factor = 10**precision
      (value * factor).round.to_f / factor
    end

    # Runs a block using VCR for HTTP caching.
    #
    # @param cassette [String] The cassette name.
    # @return [Object] The return value of the provided block.
    def caching_http_requests(cassette)
      setup_vcr if !defined?(VCR)
      VCR.use_cassette(cassette) { yield }
    end

    private
      # Setups the VCR gem.
      def setup_vcr
        require "webmock"
        require "vcr"
        require "vcr/util/version_checker"

        VCR.configure do |c|
          # Hide VCR warning about webmock
          VCR::VersionChecker.class_eval do
            private
            def warn_about_too_high
            end
          end

          c.allow_http_connections_when_no_cassette = true
          c.cassette_library_dir = @cache_dir + "/http/"
          c.default_cassette_options = {record: :new_episodes}
          c.hook_into :webmock
        end
      end

      # Gets attributes and childs for output
      #
      # @param item [Hash] The output item.
      # @return [Array] An array with child and attributes.
      def split_output_item(item)
        item.partition {|k, _| [:title, :subtitle, :icon].include?(k) }.collect {|a| array_to_hash(a) }
      end
  end
end
