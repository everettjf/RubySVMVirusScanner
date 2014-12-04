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
    print 'Start trainning on health_dir ',health_dir,'  and virus_dir ',virus_dir,"\n"

    f = File.open('train.dataset','w')

    large_dataset = []
    large_labels = []
    { health_dir => -1 , virus_dir => 1}.each do |dir, label|
      traverse_files_in_path(
          dir,
          lambda do |filepath|
            vec = RVSVector.new(filepath)
            return unless vec.parse?

            large_dataset.push(vec.values)
            large_labels.push(label)

            f.print label,' '

            vec.values.each do |key,value|
              f.print key,':',value,' '
            end
            f.print "\n"

          end
      )
    end

    problem = Libsvm::Problem.new
    parameter = Libsvm::SvmParameter.new

    parameter.eps = 0.001
    parameter.cache_size = 1
    parameter.c = 10 #32
    parameter.probability = 1
    #parameter.kernel_type = Libsvm::KernelType::RBF
    #parameter.gamma = 1.0/32 # 1.0/128
    #parameter.label_weights = {1=> -1}

    dataset = large_dataset.map{ |ary| Libsvm::Node.features(ary)}

    problem.set_examples(large_labels, dataset)

    model = Libsvm::Model.train(problem, parameter)
    model.save('virusdb.model')

    puts 'Train completed.'
  end

  def scan(path)
    puts '***************************Scan Start******************************'
    print 'Start scan ',path,"\n"

    # load model
    model = Libsvm::Model.load('virusdb.model')

    filecount = 0
    viruscount = 0

    traverse_files_in_path(
        path,
        lambda do |filepath|
          filecount = filecount + 1

          pred = scanfile(filepath,model)
          if nil == pred
            # print 'error scan :',filepath,"\n"
            return
          end

          # result
          if pred.first != -1
            viruscount = viruscount + 1
            print 'O_O Virus (',pred.first,' , ',pred.last,') ', filepath,"\n"
          end
        end
    )

    puts '--------------------------Scan Result:-----------------------------'
    puts 'Scan completed.'
    puts path
    print 'Virus / Total = ',viruscount ,'/',filecount,' (',viruscount.to_f / filecount.to_f,')'"\n"
    puts '**************************Scan Compeleted**************************'
  end

  def scanfile(filepath, model)
    vec = RVSVector.new(filepath)
    return nil unless vec.parse?

    pred = model.predict_probability(Libsvm::Node.features(vec.values))
    return pred
  end
end

if $0 == __FILE__
  RVSScanCLI.new.run
end

