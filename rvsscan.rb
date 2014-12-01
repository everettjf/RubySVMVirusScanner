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
      traverse_files_in_path(
          dir,
          lambda do |filepath|
            vec = RVSVector.new(filepath)
            return unless vec.parse?

            large_dataset.push(vec.values)
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

    filecount = 0
    viruscount = 0

    traverse_files_in_path(
        path,
        lambda do |filepath|
          filecount = filecount + 1

          puts filepath
          pred = scanfile(filepath,model)
          if pred == 0.0
            print ':) (',pred,')sames like a health file ',filepath,"\n"
          else
            viruscount = viruscount + 1
            print 'O_O (',pred,')sames like a virus file', filepath,"\n"
          end
        end
    )

    print 'virus / total = ',viruscount ,'/',filecount,"\n"
  end

  def scanfile(filepath, model)
    vec = RVSVector.new(filepath)
    pred = model.predict(Libsvm::Node.features(vec.values))
    return pred
  end
end

if $0 == __FILE__
  RVSScanCLI.new.run
end

