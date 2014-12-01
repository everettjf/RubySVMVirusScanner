#!/usr/bin/env ruby
#
#
#

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'pedump'
require 'optparse'
require 'sqlite3'
require 'rvscore'
require 'rvsfile'
require 'pp'


class RVSVector
  attr_reader :filepath, :values
  def initialize(filepath)
    @filepath = filepath
    @values = []
    @iat_map = {}
    @section_map = {}
    @file = RVSFile.new(filepath)
  end

  def parse?
    unless @file.parse?
      # print 'none pe file :', filepath, "\n"
      return false
    end

    unless prepare_map?
      print 'file prepare map failed : ', filepath, "\n"
      return false
    end

    @values = []
    push_size_vector
    push_iat_vector
    push_section_vector

    true
  end

  def push_size_vector
    if @file.filesize == 0
      @values.push(0.0)
    elsif @file.filesize < 1 * 1024 * 1024
      @values.push(1.0)
    elsif @file.filesize < 10 * 1024 * 1024
      @values.push(0.5)
    else
      @values.push(0.1)
    end
  end

  def prepare_map?
    dbpath = Dir.pwd + '/iat.db'
    unless File.exist?(dbpath)
      puts 'no iat.db file'
      return false
    end

    db = SQLite3::Database.open(dbpath)
    iat_array = db.execute('select name,weight from t_iat')
    section_array = db.execute('select name,weight from t_section')

    iat_array.each do |name, weight|
      @iat_map[name] = weight / 5.0
    end
    section_array.each do |name, weight|
      @section_map[name] = weight / 5.0
    end

    @iat_map.sort
    @section_map.sort

    true
  end

  def push_iat_vector
    file_map = {}
    @file.imports.each do |name|
      file_map[name] = nil # we do not care the value
    end

    @iat_map.each do |name, value|
      if file_map.has_key?(name)
        @values.push(value)
      else
        @values.push(0.0)
      end
    end

  end

  def push_section_vector
    file_map = {}
    @file.sections.each do |name|
      file_map[name] = nil
    end

    @section_map.each do |name,value|
      if file_map.has_key?(name)
        @values.push(value)
      else
        @values.push(0.0)
      end
    end
  end
end

# test
if $0 == __FILE__
  vec = RVSVector.new('/Users/everettjf/Virus/VirusSignList_Free_131105/Samples/virussign.com_0a0c4498d0e8deff2be8d35a4157da50.vir')
  vec.parse?

  p vec.values.size
  p vec.values
end

