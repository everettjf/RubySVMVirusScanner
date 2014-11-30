#!/usr/bin/env ruby
#
#
#

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'rvscore'
require 'pedump'
require 'optparse'
require 'sqlite3'


class RVSFile < RVSCore

  attr_reader :filepath, :filesize, :imports, :sections

  def initialize(filepath)
    @filepath = filepath
    @filesize = 0
    @imports = []
    @sections = []

  end

  def parse?
    @filesize = File.size(filepath)

    return false if filesize <= 0

    File.open(filepath,'rb') do |f|
      pedump = PEdump.new(filepath)

      begin
        @imports = fetch_pe_imports_array(pedump, f)
      rescue => ex
        puts filepath, ex.message
      end

      begin
        @sections = fetch_pe_sections_array(pedump,f)
      rescue => ex
        puts filepath, ex.message
      end
    end

    true
  end
end


