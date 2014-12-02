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

#
# values should like this : {11 => 0.11, 21 => 0.21, 101 => 0.99 })
#

class RVSVector
  attr_reader :filepath, :values
  def initialize(filepath)
    @filepath = filepath
    @values = {}
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

    plain_values = []
    push_size_vector(plain_values)
    push_company_vector(plain_values)
    push_version_vector(plain_values)
    push_packer_vector(plain_values)
    push_section_vector(plain_values)
    push_iat_vector(plain_values)

    # plain_values [] to values {}
    @values = {}
    plain_values.each_with_index do |item,index|
      #@values[index+1] = item if item != 0.0
      @values[index+1] = item
    end

    true
  end

  def push_size_vector(plain_values)
    if @file.filesize == 0
      plain_values.push(0.0)
    elsif @file.filesize < 1 * 1024 * 1024
      plain_values.push(1.0)
    elsif @file.filesize < 10 * 1024 * 1024
      plain_values.push(0.5)
    else
      plain_values.push(0.1)
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

  def push_iat_vector(plain_values)
    file_map = {}
    @file.imports.each do |name|
      file_map[name] = nil # we do not care the value
    end

    @iat_map.each do |name, value|
      plain_values.push(file_map.has_key?(name) ? value : 0.0)
    end
  end

  def push_section_vector(plain_values)
    file_map = {}
    @file.sections.each do |name|
      file_map[name] = nil
    end

    @section_map.each do |name,value|
      plain_values.push(file_map.has_key?(name) ? value : 0.0)
    end
  end

  def push_company_vector(plain_values)
    plain_values.push(@file.company.empty? ? 1.0 : 0.0)
  end

  def push_version_vector(plain_values)
    plain_values.push(@file.version.empty? ? 1.0 : 0.0)
  end

  def push_packer_vector(plain_values)
    if @file.packer.empty?
      plain_values.push(0.0)
      return
    end

    ['MS Visual','Microsoft'].each do |x|
      if @file.packer.include?(x)
        plain_values.push(0.0)
        return
      end
    end

    plain_values.push(1.0)
  end
end

# test
if $0 == __FILE__
  fpath = File.expand_path(File.dirname(__FILE__) + '/pesample/' + 'notpe.txt' )
  vec = RVSVector.new(fpath)
  vec.parse?

  p vec.values.size
  p vec.values
end

