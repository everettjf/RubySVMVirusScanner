require 'libsvm'


describe 'svmtest' do
  it 'should just test libsvm' do
    problem = Libsvm::Problem.new
    parameter = Libsvm::SvmParameter.new
    parameter.cache_size = 1 # in megabytes
    parameter.eps = 0.001
    parameter.c = 10

    examples = [
        [1.0,1.0],
        [-1.0,-1.0]
    ].map {|ary| Libsvm::Node.features(ary) }
    labels = [1.0, -1.0]

    problem.set_examples(labels, examples)

    model = Libsvm::Model.train(problem, parameter)

    model.save('test.model')

    pred = model.predict(Libsvm::Node.features([0.5,0.5]))

    puts "Example [1, 1, 1] - Predicted #{pred}"
  end
end
