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

        begin
          @imports = fetch_pe_imports_array(pedump, f)
        rescue => ex
          #puts filepath, ex.message
        end

        begin
          @sections = fetch_pe_sections_array(pedump,f)
        rescue => ex
          #puts filepath, ex.message
        end

        return false if @imports.empty? && @sections.empty?

        begin
          data = pedump.version_info(f)
          data.each do |vi|
            vi.Children.each do |file_info|
              case file_info
                when PEdump::StringFileInfo, PEdump::NE::StringFileInfo
                  file_info.Children.each do |string_table|
                    string_table.Children.each do |string|
                      @company = string.Value.inspect if string.szKey == 'CompanyName'
                      @version = string.Value.inspect if string.szKey == 'FileVersion'
                    end
                  end
              end
            end
          end
        rescue => ex
          #puts filepath, ex.message
        end

        begin
          @packer = pedump.packer.first.name
        rescue
        end
      end
    rescue
      return false
    end

    true
  end
end


