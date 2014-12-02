require 'libsvm'


describe 'svmtest' do
  puts Dir.pwd

  problem = Libsvm::Problem.new
  parameter = Libsvm::SvmParameter.new

  parameter.cache_size = 1 # in megabytes

  parameter.eps = 0.001
  parameter.c = 10

  examples = [ {1=>1}, {1=>-1} ].map {|ary| Libsvm::Node.features(ary) }
  labels = [1, -1]

  problem.set_examples(labels, examples)

  model = Libsvm::Model.train(problem, parameter)
  model.save('test.model')

  pred = model.predict(Libsvm::Node.features({1=>-1}))
  puts "Example [1, 1, 1] - Predicted #{pred}"
end
