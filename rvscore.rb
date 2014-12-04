#!/usr/bin/env ruby
#
# ruby virus scanner
# This file is some utilities for the basic scanner
#

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'pedump'
require 'optparse'
require 'sqlite3'

class RVSCore

  def fetch_pe_imports_array(pedump, f)
    imports = []
    begin
      data = pedump.imports(f)
      return [] if !data || (data.respond_to?(:empty?) && data.empty?)

      data.each do |x|
        case x
          when PEdump::IMAGE_IMPORT_DESCRIPTOR
            (Array(x.original_first_thunk) + Array(x.first_thunk)).uniq.each do |item|
              next unless item
              imports.push(item.name.to_s.encode('utf-8'))
            end
          when PEdump::ImportedFunction
            imports.push(x.name.to_s.encode('utf-8'))
          else
            raise "invalid #{x.inspect}"
        end
      end
    rescue
    end
    imports
  end

  def fetch_pe_sections_array(pedump,f)
    sections = []
    begin
      data = pedump.sections(f)
      return [] if !data || (data.respond_to?(:empty?) && data.empty?)

      data.each do |s|
        name = s.Name[/[^a-z0-9_.]/i] ? s.Name.inspect : s.Name
        name = "#{name}\n          " if name.size > 8
        sections.push(name.to_s.encode('utf-8'))
      end
    rescue
    end
    sections
  end

  def fetch_pe_version_company(pedump,f)
    company = ''
    version = ''
    begin
      data = pedump.version_info(f)
      data.each do |vi|
        vi.Children.each do |file_info|
          case file_info
            when PEdump::StringFileInfo, PEdump::NE::StringFileInfo
              file_info.Children.each do |string_table|
                string_table.Children.each do |string|
                  company = string.Value.inspect.encode('utf-8') if string.szKey == 'CompanyName'
                  version = string.Value.inspect.encode('utf-8') if string.szKey == 'FileVersion'
                end
              end
          end
        end
      end
    rescue => ex
      #puts filepath, ex.message
    end
    return version,company
  end

  def fetch_pe_packer_name(pedump)
    begin
      pedump.packer.first.name.encode('utf-8')
    rescue
    end
  end

  # @param [String] path
  # @param [Proc(String)] callback
  def traverse_files_in_path(path, callback)
    begin
      if File.directory?(path)
        dir = Dir.open(path)
        while name = dir.read
          next if name == '.'
          next if name == '..'
          traverse_files_in_path(path + '/' + name, callback)
        end
      else
        callback.call(path)
      end
    rescue => ex
      print ex
    end
  end
end

