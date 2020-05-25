# rubocop:disable Layout/LineLength
require_relative './lib/validate_file.rb'
require_relative './lib/validate_angle_brackets.rb'
require_relative './lib/error_found.rb'

describe ValidateAngleBrackets do
  let(:val_file_obj) { ValidateFile.new('text.xml', 2) }
  let(:test_array) { [] }

  describe '#create_error_bracket_inside' do
    it 'Creates an error message and push into array of errors' do
      expect(val_file_obj.create_error_bracket_inside(1, 10)).to eql(test_array.push('Line 1 with angle bracket(<) open inside another angle bracket at col 10'))
    end
  end

  describe '#create_error_bracket_unclosed' do
    it 'Creates an error message and push into array of errors' do
      expect(val_file_obj.create_error_bracket_unclosed('1')).to eql(test_array.push('Line 1 should have all angle brackets(<) closed with a matchin (>)'))
    end
  end

  describe '#check_angle_brackets' do
    it 'Loop on the line and check if not all open < are closed creates error message' do
      val_file_obj.check_angle_brackets('<testing o<pen tag inside', 1)
      expect(val_file_obj.errors.angle_bracket).to eql(test_array.push('Line 1 with angle bracket(<) open inside another angle bracket at col 10'))
    end

    it 'Loop on the line and check if not all open < are closed creates error message' do
      val_file_obj.check_angle_brackets('<test ><> <test><not close', 1)
      expect(val_file_obj.errors.angle_bracket).to eql(test_array.push('Line 1 should have all angle brackets(<) closed with a matchin (>)'))
    end
  end
end
# rubocop:enable Layout/LineLength
