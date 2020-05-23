# rubocop:disable 
require './lib/validate_file.rb'
require './lib/validate_angle_brackets.rb'
require './lib/error_found.rb'

describe ValidateFile do
  let(:val_file_obj) { ValidateFile.new('text.xml', 2) }
  let(:test_hash) { {} }
  let(:test_array) { [] }

  describe '#check_line' do
    it 'call methods to check open tags, close tags and identation on that line' do
    
    end
  end

  describe '#check_unclosed_tags' do
    it 'check if the stack of open tags has anything, creates one error message to each tag found' do
      val_file_obj.open_tags_hash['Tag'] = [1, 1]
      test_hash['Tag'] = "Unclosed tag 'Tag' on line 1"
      val_file_obj.check_unclosed_tags
      expect(val_file_obj.errors.open_tag).to eql(test_hash)
    end
  end

  describe '#next_open_index' do
    it 'Search the line for next open tag returning position of tag and line' do
      test_array[0] = 2
      test_array[1] = "  <Tag> \n"
      expect(val_file_obj.next_open_index("  <Tag> \n")).to eql(test_array)
    end
  end
end
# rubocop:enable
