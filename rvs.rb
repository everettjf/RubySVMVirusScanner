#!/usr/bin/env ruby
# ruby virus scanner

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'pedump'
require 'optparse'
require 'sqlite3'

class RVS

  def fetch_file_imports_array(pedump, f)
    data = pedump.imports(f)
    return [] if !data || (data.respond_to?(:empty?) && data.empty?)

    imports = []
    data.each do |x|
      case x
        when PEdump::IMAGE_IMPORT_DESCRIPTOR
          (Array(x.original_first_thunk) + Array(x.first_thunk)).uniq.each do |item|
            next unless item
            imports.push(item.name.to_s)
          end
        when PEdump::ImportedFunction
          imports.push(x.name.to_s)
        else
          raise "invalid #{x.inspect}"
      end
    end
    imports
  end

  def fetch_file_sections_array(pedump,f)
    data = pedump.sections(f)
    return [] if !data || (data.respond_to?(:empty?) && data.empty?)

    sections = []
    data.each do |s|
      name = s.Name[/[^a-z0-9_.]/i] ? s.Name.inspect : s.Name
      name = "#{name}\n          " if name.size > 8
      sections.push(name.to_s)
    end
    sections
  end


  def traverse_files_in_dir(path, callback)
    if File.directory?(path)
      dir = Dir.open(path)
      while name = dir.read
        next if name == '.'
        next if name == '..'
        traverse_files_in_dir(path + '/' + name, callback)
      end
    else
      callback.call(path)
    end
    end
end
