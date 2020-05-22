require './lib/error_found.rb'

describe ErrorFound do
  let(:test_hash) { { 'one' => 'Message 1', 'two' => 'Message 2', 'three' => 'Message 3' } }
  let(:error_obj) { ErrorFound.new }
  
  describe '#reader' do 
    it 'Return ident errors from array of errors' do
      error_obj.ident.push('testErrorMessage1')
      error_obj.ident.push('testErrorMessage2')
      error_obj.ident.push('testErrorMessage3')
      expect(error_obj.ident).to eql(%w[ testErrorMessage1 testErrorMessage2 testErrorMessage3 ])
    end
    it 'Return angle_bracket errors from array of errors' do
      error_obj.angle_bracket.push('testErrorMessage1')
      error_obj.angle_bracket.push('testErrorMessage2')
      error_obj.angle_bracket.push('testErrorMessage3')
      expect(error_obj.angle_bracket).to eql(%w[ testErrorMessage1 testErrorMessage2 testErrorMessage3 ])
    end
    it 'Return open tag errors from hash of errors' do
        error_obj.open_tag['one'] = 'Message 1'
        error_obj.open_tag['two'] = 'Message 2'
        error_obj.open_tag['three'] = 'Message 3'
      expect(error_obj.open_tag).to eql(test_hash)
    end
    it 'Return close errors from hash of errors' do
        error_obj.close_tag['one'] = 'Message 1'
        error_obj.close_tag['two'] = 'Message 2'
        error_obj.close_tag['three'] = 'Message 3'
      expect(error_obj.close_tag).to eql(test_hash)
    end
  end
end

