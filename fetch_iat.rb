#!/usr/bin/env ruby

require 'pedump'
require 'optparse'
require 'sqlite3'

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
        filepath = argv[1]
        print_file(filepath)
      end

      opts.on '--dir','Save IAT and Sections into database in the directory' do
        dirpath = argv[1]
        save_dir(dirpath)
      end
    end

    if (@argv = optparser.parse(@argv)).empty?
      puts optparser.help
      return
    end

  end

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


  def print_file(filepath)
    File.open(filepath,'rb') do |f|
      pedump = PEdump.new(filepath)
      puts "imports:"
      begin
        imports = fetch_file_imports_array(pedump,f)
        p imports
      rescue => ex
        puts ex.message
      end

      puts "sections:"
      begin
        sections = fetch_file_sections_array(pedump,f)
        p sections
      rescue => ex
        puts ex.message
      end
    end
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

  def save_dir(dirpath)
    # create db
    dbpath = Dir.pwd + '/iat.db'
    File.delete(dbpath) if File.exist?(dbpath)

    db = SQLite3::Database.open(dbpath)
    db.execute <<-SQL
      create table t_iat(
        name text primary key,
        weight int
      )
    SQL
    db.execute <<-SQL
      create table t_section(
        name text primary key,
        weight int
      )
    SQL

    db.execute('begin transaction')
    traverse_files_in_dir(
        dirpath,
        lambda do |filepath|
          File.open(filepath,'rb') do |f|
            pedump = PEdump.new(filepath)

            begin
              imports = fetch_file_imports_array(pedump, f)

              imports.each do |name|
                db.execute('replace into t_iat values(?,?)',[name,1])
              end
            rescue => ex
              puts filepath, ex.message
            end

            begin
              sections = fetch_file_sections_array(pedump,f)
              sections.each do |name|
                db.execute('replace into t_section values(?,?)',[name,1])
              end
            rescue => ex
              puts filepath, ex.message
            end
          end
        end
    )
    db.execute('end transaction')
  end
end

# run
RVM::CLI.new.run


