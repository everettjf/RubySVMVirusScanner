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

  attr_reader :filepath, :filesize, :imports, :sections, :company
  attr_reader :version, :packer

  def initialize(filepath)
    @filepath = filepath
    @filesize = 0
    @imports = []
    @sections = []
    @company = ''
    @version = ''
    @packer = ''
  end

  def parse?
    begin
      @filesize = File.size(filepath)
      return false if filesize == 0

      File.open(filepath,'rb') do |f|
        pedump = PEdump.new(f).tap do |x|
          x.logger.level = Logger::UNKNOWN
        end

        @imports = fetch_pe_imports_array(pedump, f)
        @sections = fetch_pe_sections_array(pedump,f)
        return false if @imports.empty? && @sections.empty?

        @version,@company = fetch_pe_version_company(pedump,f)
        @packer = fetch_pe_packer_name(pedump)
      end
    rescue
      return false
    end

    true
  end
end



