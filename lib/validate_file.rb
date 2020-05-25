# rubocop:disable Metrics/ClassLength
require_relative 'error_found.rb'
require_relative 'validate_angle_brackets.rb'

class ValidateFile
  include ValidateAngleBrackets
  attr_reader :file_name, :errors, :error_number
  attr_accessor :open_tags_hash

  def initialize(file, space_ident)
    @file_name = file
    @space_ident = space_ident
    @open_tags_hash = Hash.new([])
    @index_open = 0
    @index_close = 0
    @ident_line = 1
    @spaces_id = 0
    @errors = ErrorFound.new
    @error_number = 0
    @root_element = ''
    @closed_root = false
    @tried_close_more_roots = false
    @last_close_key = ''
  end

  def check_unclosed_tags
    @open_tags_hash.each do |n|
      @error_number += 1
      @errors.open_tag[n.first] = "Unclosed tag '#{n.first}' on line #{@open_tags_hash[n.first][1]}"
    end
    return unless @tried_close_more_roots || @last_close_key != @root_element

    @error_number += 1
    @errors.open_tag[:root_element] = 'XML file without root element that encompasses all XML'
  end

  def next_open_index(line)
    ret_arr = []
    ret_arr[0] = -1
    ret_arr[1] = line
    start_tag = -1
    until start_tag.nil?
      start_tag = ret_arr[1].index('<')
      end_tag = ret_arr[1].index('</')
      unless end_tag == start_tag
        ret_arr[0] = start_tag
        return ret_arr
      end
      next if start_tag.nil?

      cutted_line = ret_arr[1][start_tag..-1]
      cutted_line = cutted_line[1..-1]
      ret_arr[1] = cutted_line
    end
    ret_arr[0] = -1 if end_tag == start_tag
    ret_arr
  end

  def create_open_error(tag, index)
    @error_number += 1
    error_tag = @error_number.to_s + tag
    @errors.open_tag[error_tag] = "Duplicated open tag '#{tag}' on line #{index}"
    @errors.open_tag[error_tag].concat(" (tag was open but not closed at line #{@open_tags_hash[tag][1]})")
  end

  def create_error_tag_name(tag, index)
    @error_number += 1
    error_tag = @error_number.to_s + tag
    @errors.open_tag[error_tag] = "Tag name invalid '#{tag}' on line #{index} tag must not start with numbers or spaces"
  end

  def check_open_errors(tag, index)
    if tag.size.zero? || !/\A\d+/.match(tag).nil?
      tag = 'start with empty space' if tag.size.zero?
      create_error_tag_name(tag, index)
    end
    if @open_tags_hash[tag] != []
      create_open_error(tag, index)
    else
      @index_open += 1
      @open_tags_hash[tag] = [@index_open, index]
      see_root_elem(tag)
    end
  end

  def see_root_elem(tag)
    return unless @root_element == '' && @index_open == 1

    @root_element = tag
  end

  def open_tags(line, index)
    ret_ar = next_open_index(line)
    start_tag = ret_ar[0]
    return if start_tag == -1

    until start_tag == -1 || ret_ar[1][start_tag..-1].nil?
      cutted_line = ret_ar[1][start_tag..-1]
      finish_tag = cutted_line.index(/[ >\n]/)
      tag = cutted_line[1..finish_tag - 1]
      check_open_errors(tag, index)
      cutted_line = cutted_line[1..-1]
      line = cutted_line
      ret_ar = next_open_index(line)
      start_tag = ret_ar[0]
      line = ret_ar[1]
    end
  end

  def next_close_index(line)
    ret_arr = []
    ret_arr[0] = -1
    ret_arr[1] = line
    start_tag = -1
    unless start_tag.nil?
      start_tag = ret_arr[1].index('</')
      unless start_tag.nil?
        cutted_line = ret_arr[1][start_tag..-1]
        cutted_line = cutted_line[1..-1]
        ret_arr[0] = start_tag
        ret_arr[1] = cutted_line
      end
    end
    ret_arr
  end

  def last_open_tag
    last_open = @open_tags_hash.max_by { |_k, v| v[0] }
    last_open&.first
  end

  def tag_was_open?(key)
    @open_tags_hash.key?(key)
  end

  def remove_open_tag(key)
    if key == @root_element
      if @closed_root
        @tried_close_more_roots = true
      else
        @closed_root = true
      end
    end
    @last_close_key = key
    @open_tags_hash.delete(key) if @open_tags_hash[key]
  end

  def create_close_error_not_opened(tag, index)
    @error_number += 1
    error_tag = @error_number.to_s + tag
    @errors.close_tag[error_tag] = "Tried to close tag '#{tag}' on line #{index} without opening"
  end

  def create_close_error_nasted(tag, index)
    @error_number += 1
    error_tag = @error_number.to_s + tag
    @errors.close_tag[error_tag] = "Tried to close tag '#{tag}' on line #{index} "
    @errors.close_tag[error_tag].concat("with tag '#{last_open_tag}' still opened")
  end

  def check_close_errors(tag, index)
    if !tag_was_open?(tag)
      create_close_error_not_opened(tag, index)
      @index_close += 1
    elsif last_open_tag != tag
      create_close_error_nasted(tag, index)
      remove_open_tag(tag)
      @index_open -= 1
    else
      remove_open_tag(tag)
      @index_open -= 1
    end
  end

  def close_tags(line, index)
    ret_ar = next_close_index(line)
    start_tag = ret_ar[0]
    return if start_tag == -1

    until start_tag == -1 || ret_ar[1].nil?
      cutted_line = ret_ar[1]
      finish_tag = cutted_line.index(/[ >\n]/)
      tag = cutted_line[1..finish_tag - 1]
      tag = 'start with empty space' if tag.size.zero?
      check_close_errors(tag, index)
      cutted_line = cutted_line[1..-1]
      line = cutted_line
      ret_ar = next_close_index(line)
      start_tag = ret_ar[0]
      line = ret_ar[1]
    end
  end

  def identation(line, index)
    actual_spaces = @spaces_id
    @spaces_id = (@index_open - @index_close) * @space_ident
    start_tag = line.index(/\S/)
    return if index.to_i != @ident_line

    if line.strip == ''
      @error_number += 1
      @errors.ident.push("Blank line detected on line #{@ident_line}")
    else
      actual_spaces -= 2 if line.slice(start_tag, 2) == '</'
      unless start_tag == actual_spaces
        @error_number += 1
        @errors.ident.push("Identation error on line #{@ident_line} should have #{actual_spaces} spaces")
      end
    end
    @ident_line += 1
  end

  def check_line(line)
    index = line.scan(/\d+/).pop
    line = line.gsub(line.scan(/ \d+/).pop, '')
    open_tags(line, index)
    close_tags(line, index)
    identation(line, index)
  end
end
# rubocop:enable Metrics/ClassLength
