require_relative 'error_found.rb'

class ValidateFile < ErrorFound
  attr_reader :file_name, :errors, :error_number

  def initialize(file, space_ident)
    @file_name = file
    @space_ident = space_ident
    @open_tags_hash = Hash.new([])
    @index_open = 0
    @closing_tags_hash = Hash.new([])
    @index_close = 0
    @ident_line = 1
    @ident_err = 0
    @spaces_id = 0
    @errors = ErrorFound.new
    @error_number = 0
  end

  def check_line(line)
    index = line.scan(/\d+/).pop
    line = line.gsub(line.scan(/\d+/).pop, '')
    open_tags(line, index)
    close_tags(line, index)
    identation(line, index)
  end

  # Check after looping for the file, if any open tag was not closed
  def check_unclosed_tags
    @open_tags_hash.each do |n|
      @error_number += 1
      @errors.open_tag[n.first] = "Unclosed tag '#{n.first}' on line #{@open_tags_hash[n.first][1]}"
    end
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

  def open_tags(line, index)
    ret_ar = next_open_index(line)
    start_tag = ret_ar[0]
    return if start_tag == -1

    until start_tag == -1 || ret_ar[1][start_tag..-1].nil?
      cutted_line = ret_ar[1][start_tag..-1]
      finish_tag = cutted_line.index(/[ >\n]/)
      tag = cutted_line[1..finish_tag - 1]
      if @open_tags_hash[tag] != [] || tag.size.zero?
        create_open_error(tag, index)
      else
        @index_open += 1
        @open_tags_hash[tag] = [@index_open, index]
      end
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

  # Search for the last tag opened withous closing
  def last_open_tag
    last_open = @open_tags_hash.max_by { |_k, v| v[0] }
    last_open.first
  end

  # Check if the tag is already open
  def tag_was_open?(key)
    @open_tags_hash.key?(key)
  end

  # When closing tag, remove from the list of open tags
  def remove_open_tag(key)
    @open_tags_hash.delete(key) if @open_tags_hash[key]
  end

  def create_close_error_not_opened(tag, index)
    @error_number += 1
    error_tag = @error_number.to_s + tag
    @errors.close_tag[error_tag] = "Tried to close tag '#{tag}' on line #{index} without opening"
  end

  def create_close_error_nasted(tag, index, last_open_tag)
    @error_number += 1
    error_tag = @error_number.to_s + tag
    @errors.close_tag[error_tag] = "Tried to close tag '#{tag}' on line #{index} "
    @errors.close_tag[error_tag].concat("with tag '#{last_open_tag}' still opened")
  end

  def check_close_errors(tag, index, last_open_tag)
    if !tag_was_open?(tag)
      create_close_error_not_opened(tag, index)
      @index_close += 1
      @closing_tags_hash[tag] = [@index_close, index]
    elsif last_open_tag != tag
      create_close_error_nasted(tag, index, last_open_tag)
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
      check_close_errors(tag, index, last_open_tag)
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
      @errors.ident[@ident_err] = "Blank line detected on line #{@ident_line}"
      @ident_err += 1
    else
      actual_spaces -= 2 if line.slice(start_tag, 2) == '</'
      unless start_tag == actual_spaces
        @error_number += 1
        @errors.ident[@ident_err] = "Identation error on line #{@ident_line} should have #{actual_spaces} spaces"
        @ident_err += 1
      end
    end
    @ident_line += 1
  end
end
