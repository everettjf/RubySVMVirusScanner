#!/usr/bin/env ruby
#
#
#

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'rvscore'
require 'rvsvector'
require 'libsvm'

class RVSScanCLI < RVSCore
  attr_accessor :argv

  def initialize(argv=ARGV)
    @argv = argv
  end

  def run
    optparser = OptionParser.new do |opts|
      opts.banner = 'Usage: train [options]'

      opts.on '--train','Train on specified "health_dir" and "virus_dir" ' do
        health_dir = argv[1]
        virus_dir = argv[2]

        train(health_dir, virus_dir)
      end

      opts.on '--scan','Scan file or directory' do
        path = argv[1]
        scan(path)
      end

    end

    if (@argv = optparser.parse(@argv)).empty?
      puts optparser.help
      return
    end
  end

  def train(health_dir, virus_dir)
    large_dataset = []
    large_labels = []
    { health_dir => 0 , virus_dir => 1}.each do |dir, label|
      traverse_files_in_dir(
          dir,
          lambda do |filepath|
            vec = RVSVector.new(filepath)
            return unless vec.parse?

            large_dataset.push(vec)
            large_labels.push(label)
          end
      )
    end

    problem = Libsvm::Problem.new
    parameter = Libsvm::SvmParameter.new

    parameter.cache_size = 1 # in megabytes
    parameter.eps = 0.001
    parameter.c = 10

    dataset = large_dataset.map{ |ary| Libsvm::Node.features(ary)}
    problem.set_examples(large_labels, dataset)

    model = Libsvm::Model.train(problem, parameter)
    model.save('virusdb.model')

  end

  def scan(path)
    # load model
    model = Libsvm::Model.load('virusdb.model')

    if File.directory?(path)
      # dir traverse
      traverse_files_in_dir(
          path,
          lambda do |filepath|
            scan(filepath)
          end
      )
    else
      # file
      vec = RVSVector.new(path)
      pred = model.predict(Libsvm::Node.features(vec))
      print 'pridiction :',pred
      if pred == 0.0
        puts 'sames like a health file'
      else
        puts 'sames like a virus'
      end
    end
  end
end

if $0 == __FILE__
  RVSScanCLI.new.run
end

