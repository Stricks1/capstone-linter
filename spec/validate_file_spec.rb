# rubocop:disable
require './lib/validate_file.rb'
require './lib/validate_angle_brackets.rb'
require './lib/error_found.rb'

describe ValidateFile do
  let(:val_file_obj) { ValidateFile.new('text.xml', 2) }
  let(:val_file_obj2) { ValidateFile.new('text.xml', 2) }
  let(:test_hash) { {} }
  let(:test_array) { [] }
  let(:test_line) { '' }
  let(:test_line2) { '' }

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

  describe '#create_open_error' do
    it 'Create duplicate error on open tags error object' do
      val_file_obj.open_tags_hash['Tag'] = [1, 1]
      test_hash['Tag'] = "Duplicated open tag 'Tag' on line 2 (tag was open but not closed at line 1)"
      expect(val_file_obj.create_open_error('Tag', 2)).to eql(test_hash['Tag'])
    end
  end

  describe '#create_error_tag_name' do
    it 'Create invalid tag name error on open tags error object' do
      test_hash['1Tag'] = "Tag name invalid '1Tag' on line 2 tag must not start with numbers or spaces"
      expect(val_file_obj.create_error_tag_name('1Tag', 2)).to eql(test_hash['1Tag'])
    end
  end

  describe '#check_open_errors' do
    it 'Given duplicated tag it just creates a duplicate error' do
      val_file_obj.open_tags_hash['Tag'] = [1, 1]
      expect(val_file_obj.check_open_errors('Tag', 2)).to eql(val_file_obj.create_open_error('Tag', 2))
    end

    it 'Given unopen tag it creates array for open_tags_hash' do
      test_array[0] = 1
      test_array[1] = 2
      expect(val_file_obj.check_open_errors('Tag', 2)).to eql(test_array)
    end
  end

  describe '#open_tags' do
    it 'Get all tags from the line, save on the opened hash and return nil after finished' do
      test_line = '<tag><sec>some info</sec> </tag>'
      test_hash['tag'] = [1, 1]
      test_hash['sec'] = [2, 1]
      expect(val_file_obj.open_tags(test_line, 1)).to eql(nil)
      expect(val_file_obj.open_tags_hash).to eql(test_hash)
    end
  end

  describe '#next_close_index' do
    it 'Search the line for next close tag returning position of tag and line shifted info until close tag' do
      test_array[0] = 2
      test_array[1] = "/Tag> \n"
      expect(val_file_obj.next_close_index("  </Tag> \n")).to eql(test_array)
    end
  end

  describe '#last_open_tag' do
    it 'Search for the last opened tag on stack of open tags return the tag name (key)' do
      val_file_obj.open_tags_hash['First'] = [1, 1]
      val_file_obj.open_tags_hash['Tag'] = [2, 1]
      val_file_obj.open_tags_hash['Last'] = [3, 4]
      expect(val_file_obj.last_open_tag).to eql('Last')
    end
  end

  describe '#tag_was_open?' do
    it 'Return true if the tag is already open on the stack of open tags' do
      val_file_obj.open_tags_hash['First'] = [1, 1]
      val_file_obj.open_tags_hash['Tag'] = [2, 1]
      val_file_obj.open_tags_hash['Last'] = [3, 4]
      expect(val_file_obj.tag_was_open?('First')).to eql(true)
    end

    it 'Return false if the tag is not open on the stack of open tags' do
      val_file_obj.open_tags_hash['First'] = [1, 1]
      val_file_obj.open_tags_hash['Tag'] = [2, 1]
      val_file_obj.open_tags_hash['Last'] = [3, 4]
      expect(val_file_obj.tag_was_open?('Test')).to eql(false)
    end
  end

  describe '#remove_open_tag' do
    it 'Remove tag from the stack of open tags if tag exists, returns deleted value' do
      val_file_obj.open_tags_hash['First'] = [1, 1]
      val_file_obj.open_tags_hash['Tag'] = [2, 1]
      val_file_obj.open_tags_hash['Last'] = [3, 4]
      expect(val_file_obj.remove_open_tag('Tag')).to eql([2, 1])
    end

    it 'When key doesnt exists to delete, return nil' do
      val_file_obj.open_tags_hash['First'] = [1, 1]
      val_file_obj.open_tags_hash['Tag'] = [2, 1]
      val_file_obj.open_tags_hash['Last'] = [3, 4]
      expect(val_file_obj.remove_open_tag('Test')).to eql(nil)
    end
  end

  describe '#create_close_error_not_opened' do
    it 'Create error for close without open on close tags error object' do
      val_file_obj.open_tags_hash['Tag'] = [1, 1]
      test_hash['Tag'] = "Tried to close tag 'Tag' on line 2 without opening"
      expect(val_file_obj.create_close_error_not_opened('Tag', 2)).to eql(test_hash['Tag'])
    end
  end

  describe '#create_close_error_nasted' do
    it 'Create error for close wrong tag on close tags error object' do
      val_file_obj.open_tags_hash['Last'] = [3, 4]
      test_hash['Tag'] = "Tried to close tag 'Tag' on line 5 with tag 'Last' still opened"
      expect(val_file_obj.create_close_error_nasted('Tag', 5)).to eql(test_hash['Tag'])
    end
  end

  describe '#check_close_errors' do
    it 'Check for errors on close tags if tag not open increase index of closed and return it' do
      expect(val_file_obj.check_close_errors('Tag', 5)).to eql(1)
    end

    it 'Check for errors on close tags if tag was open, close it and return new index of open tags' do
      val_file_obj.check_open_errors('First', 1)
      val_file_obj.check_open_errors('Tag', 2)
      expect(val_file_obj.check_close_errors('Tag', 5)).to eql(1)
    end
  end

  describe '#close_tags' do
    it 'Get all close tags from the line, close the matching on the stack of open tags return nil after' do
      test_line = '<first><tag><sec>some info</sec> </tag>'
      test_hash['first'] = [1, 1]
      val_file_obj.open_tags(test_line, 1)
      expect(val_file_obj.close_tags(test_line, 1)).to eql(nil)
      expect(val_file_obj.open_tags_hash).to eql(test_hash)
    end
  end

  describe '#identation' do
    it 'Check identation spaces and create error if wrong identation found, return next line to check' do
      test_line = "  <first>some info \n"
      test_line2 = "<sec>second info \n"
      val_file_obj.open_tags(test_line, 1)
      val_file_obj.close_tags(test_line, 1)
      val_file_obj.open_tags(test_line2, 2)
      val_file_obj.close_tags(test_line2, 2)
      test_array.push('Identation error on line 1 should have 0 spaces')
      test_array.push('Identation error on line 2 should have 4 spaces')
      expect(val_file_obj.identation(test_line, 1)).to eql(2)
      expect(val_file_obj.identation(test_line2, 2)).to eql(3)
      expect(val_file_obj.errors.ident).to eql(test_array)
    end

    it 'Check if blank spaces and create error, return next line to check' do
      test_line = "  <first>some info \n"
      test_line2 = "   \n"
      val_file_obj.open_tags(test_line, 1)
      val_file_obj.close_tags(test_line, 1)
      val_file_obj.open_tags(test_line2, 2)
      val_file_obj.close_tags(test_line2, 2)
      test_array.push('Identation error on line 1 should have 0 spaces')
      test_array.push('Blank line detected on line 2')
      expect(val_file_obj.identation(test_line, 1)).to eql(2)
      expect(val_file_obj.identation(test_line2, 2)).to eql(3)
      expect(val_file_obj.errors.ident).to eql(test_array)
    end
  end

  describe '#check_line' do
    it 'call methods to check open tags, close tags and identation on line (update errors and stack open tags)' do
      val_file_obj.check_line("  <first>some info<second>second</second> 1\n")
      test_array.push('Identation error on line 1 should have 0 spaces')
      val_file_obj2.open_tags_hash['first'] = [1, '1']
      expect(val_file_obj.errors.ident).to eql(test_array)
      expect(val_file_obj.open_tags_hash).to eql(val_file_obj2.open_tags_hash)
    end
  end
end
# rubocop:enable
