require File.expand_path(File.dirname(__FILE__) + '/../rvsfile')

%w'notepad.exe calc_upx.exe'.each do |fname|

  describe fname do
    it 'should get all file original features' do
      fname = File.expand_path(File.dirname(__FILE__) + '/../pesample/' + fname)
      file = RVSFile.new(fname)
      expect(file.parse?).to be true

      puts '------path',file.filepath
      puts '------size',file.filesize
      puts '------packer',file.packer
      puts '------version',file.version
      puts '------company',file.company
      puts '------imports',file.imports
      puts '------sections',file.sections

    end
  end
end
