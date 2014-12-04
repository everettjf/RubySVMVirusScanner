#!/usr/bin/env ruby
#
# This file is just a utility to produce the 'iat.db' database.
# Get IAT and Sections of files in the directory , and insert into iat*.db with below weight.
# So, you should prepare 2 directories which one is for health files and another is for virus files.
# weight :
#   0 : none
#   1 : health file only
#   2 : both
#   3 : virus only
#

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'rvscore'
require 'optparse'
require 'sqlite3'
require 'rvsfile'

class CLIFetchIAT < RVSCore
  attr_accessor :argv

  def initialize(argv=ARGV)
    @argv = argv
  end

  def run
    optparser = OptionParser.new do |opts|
      opts.banner = 'Usage: fetch_iat [options]'

      opts.on '--file','Print a file IAT and Sections' do
        filepath = argv[1]
        print_file(filepath)
      end

      opts.on '--health','Save "iat_health.db" Heath File IAT and Sections into database in the directory' do
        dirpath = argv[1]
        save_dir(dirpath,false)
      end

      opts.on '--virus','Save "iat_virus.db" Virus File IAT and Sections into database in the directory' do
        dirpath = argv[1]
        save_dir(dirpath,true)
      end

      opts.on '--merge','Merge "iat_health.db" with "iat_virus.db" into "iat.db" , and adjust its weight' do
        merge_file
      end
    end

    if (@argv = optparser.parse(@argv)).empty?
      puts optparser.help
      return
    end

  end

  def print_file(filepath)
    file = RVSFile.new(filepath)
    unless file.parse?
      puts 'parse file failed.'
    end

    p 'filepath:'
    p file.filepath

    p 'filesize:'
    p file.filesize

    p 'version:'
    p file.version

    p 'company:'
    p file.company

    p 'packer:'
    p file.packer

    p 'imports:'
    p file.imports

    p 'sections:'
    p file.sections
  end

  def create_tables(db)
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
  end

  def save_dir(dirpath, isvirus)
    # create db
    dbname = isvirus ? '/iat_virus.db' : '/iat_health.db'
    dbpath = Dir.pwd + dbname
    File.delete(dbpath) if File.exist?(dbpath)

    db = SQLite3::Database.open(dbpath)
    create_tables(db)

    db.execute('begin transaction')
    traverse_files_in_path(
        dirpath,
        lambda do |filepath|
          file = RVSFile.new(filepath)

          unless file.parse?
            # print 'file can not parse', filepath, '\n'
            next
          end

          begin
            imports = file.imports

            imports.each do |name|
              db.execute('replace into t_iat values(?,?)',[name,0])
            end
          rescue => ex
            puts filepath, ex.message
          end

          begin
            sections = file.sections
            sections.each do |name|
              db.execute('replace into t_section values(?,?)',[name,0])
            end
          rescue => ex
            puts filepath, ex.message
          end
        end
    )
    db.execute('end transaction')
  end

  def merge_file
    dbpath_health = Dir.pwd + '/iat_health.db'
    dbpath_virus = Dir.pwd + '/iat_virus.db'
    unless File.exist?(dbpath_health) && File.exist?(dbpath_virus)
      puts 'iat_health.db and iat_virus.db required'
      return
    end

    dbpath = Dir.pwd + '/iat.db'
    File.delete(dbpath) if File.exist?(dbpath)

    db = SQLite3::Database.open(dbpath)
    create_tables(db)

    db_health = SQLite3::Database.open(dbpath_health)
    db_virus = SQLite3::Database.open(dbpath_virus)

    # iat
    iat_health = db_health.execute('select name from t_iat').flatten!
    iat_virus = db_virus.execute('select name from t_iat').flatten!

    iat_res = iat_health & iat_virus
    iat_health_res = iat_health - iat_virus
    iat_virus_res = iat_virus - iat_health

    db.execute('begin transaction')
    iat_res.each do |name|
      db.execute('replace into t_iat values(?,?)',[name,2])
    end
    iat_health_res.each do |name|
      db.execute('replace into t_iat values(?,?)',[name,1])
    end
    iat_virus_res.each do |name|
      db.execute('replace into t_iat values(?,?)',[name,3])
    end
    db.execute('end transaction')

    # sections
    sec_health = db_health.execute('select name from t_section').flatten!
    sec_virus = db_virus.execute('select name from t_section').flatten!

    sec_res = sec_health & sec_virus
    sec_health_res = sec_health - sec_virus
    sec_virus_res = sec_virus - sec_health

    db.execute('begin transaction')
    sec_res.each do |name|
      db.execute('replace into t_section values(?,?)',[name,2])
    end
    sec_health_res.each do |name|
      db.execute('replace into t_section values(?,?)',[name,1])
    end
    sec_virus_res.each do |name|
      db.execute('replace into t_section values(?,?)',[name,3])
    end
    db.execute('end transaction')

    puts 'Merge Finish'
  end
end

# run
if $0 == __FILE__
  CLIFetchIAT.new.run
end



