#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../lib'))
require 'pedump'
require 'optparse'

class RVM

end

class RVM::CLI
  attr_accessor :data, :argv

  def initialize(argv=ARGV)
    @argv = argv
  end

  def run
    optparser = OptionParser.new do |opts|
      opts.banner = 'Usage: fetch_iat [options]'
      opts.on '--version','Print version information and exit' do
        puts '0.0.0.1'
        exit
      end

      opts.on '--file','Print a file IAT and Sections' do
        filename = argv[1]
        print_file(filename)
      end

      opts.on '--dir','Save IAT and Sections into database in the directory' do
        dirname = argv[1]
        print_dir(dirname)
      end
    end

    if (@argv = optparser.parse(@argv)).empty?
      puts optparser.help
      return
    end

  end

  def print_file(filename)
    File.open(filename,'rb') do |f|
      pedump = PEdump.new(filename)

      # imports
      data_imports = pedump.imports(f)
      return if !data_imports || (data_imports.respond_to?(:empty?) && data_imports.empty?)

      fmt_imports = "%-15s %5s %5s  %s\n"
      printf fmt_imports, "MODULE_NAME", "HINT", "ORD", "FUNCTION_NAME"

      data_imports.each do |x|
        case x
          when PEdump::IMAGE_IMPORT_DESCRIPTOR
            (Array(x.original_first_thunk) + Array(x.first_thunk)).uniq.each do |f|
              next unless f
              # imported function
              printf '-'
              printf fmt_imports,
                     x.module_name,
                     f.hint ? f.hint.to_s(16) : '',
                     f.ordinal ? f.ordinal.to_s(16) : '',
                     f.name
            end
          when PEdump::ImportedFunction
            printf fmt_imports,
                   x.module_name,
                   x.hint ? x.hint.to_s(16) : '',
                   x.ordinal ? x.ordinal.to_s(16) : '',
                   x.name
          else
            raise "invalid #{x.inspect}"
        end
      end

      # sections
      data_sections = pedump.sections(f)
      return if !data_sections || (data_sections.respond_to?(:empty?) && data_sections.empty?)

      printf "  %-8s %8s %8s %8s %8s %5s %8s %5s %8s  %8s\n",
             'NAME', 'RVA', 'VSZ','RAW_SZ','RAW_PTR','nREL','REL_PTR','nLINE','LINE_PTR','FLAGS'
      data_sections.each do |s|
        name = s.Name[/[^a-z0-9_.]/i] ? s.Name.inspect : s.Name
        name = "#{name}\n          " if name.size > 8
        printf "  %-8s %8x %8x %8x %8x %5x %8x %5x %8x  %8x  %s\n", name.to_s,
               s.VirtualAddress.to_i,      s.VirtualSize.to_i,
               s.SizeOfRawData.to_i,       s.PointerToRawData.to_i,
               s.NumberOfRelocations.to_i, s.PointerToRelocations.to_i,
               s.NumberOfLinenumbers.to_i, s.PointerToLinenumbers.to_i,
               s.flags.to_i,               s.flags_desc
      end
    end
  end

  def print_dir dirname

  end
end

# run
RVM::CLI.new.run


