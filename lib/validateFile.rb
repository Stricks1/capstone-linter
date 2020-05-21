require_relative "errorFound.rb"

class ValidateFile < ErrorFound
  attr_reader :file_name, :errors

  def initialize(file)
    @file_name = file
    @open_tags_hash = Hash.new([])
    @index_open = 0
    @closing_tags_hash = Hash.new([])
    @index_close = 0
    @errors = ErrorFound.new
    @error_number = 0
  end

  def check_line(line)
    index = line.scan(/\d+/).pop
    self.open_tags(line, index)
    self.close_tags(line, index)
    #    self.identation(line, index)
  end

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
      start_tag = ret_arr[1].index("<")
      end_tag = ret_arr[1].index("</")
      unless end_tag == start_tag
        ret_arr[0] = start_tag
        return ret_arr
      end
      unless start_tag.nil?
        cutted_line = ret_arr[1][start_tag..-1]
        cutted_line = cutted_line[1..-1]
        ret_arr[1] = cutted_line
      end
    end
    if end_tag == start_tag
      ret_arr[0] = -1
    end
    ret_arr
  end

  def open_tags(line, index)
    ret_ar = next_open_index(line)
    start_tag = ret_ar[0]
    line = ret_ar[1]
    return if start_tag == -1

    until start_tag == -1 || ret_ar[1][start_tag..-1].nil?
      cutted_line = ret_ar[1][start_tag..-1]
      finish_tag = cutted_line.index(/[ >\n]/)
      tag = cutted_line[1..finish_tag - 1]
      if @open_tags_hash[tag] != [] || tag.size == 0
        @error_number += 1
        error_tag = @error_number.to_s + tag
        @errors.open_tag[error_tag] = "Duplicated open tag '#{tag}' on line #{index} (tag was open but not closed at line #{@open_tags_hash[tag][1]})"
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
      start_tag = ret_arr[1].index("</")
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
    last_open = @open_tags_hash.max_by { |k, v| v[0] }
    last_open.first
  end

  def tag_was_open?(key)
    @open_tags_hash.has_key?(key)
  end

  def remove_open_tag(key)
    @open_tags_hash.delete(key) if @open_tags_hash[key]
  end

  def close_tags(line, index)
    full_line = line
    ret_ar = next_close_index(line)
    start_tag = ret_ar[0]
    line = ret_ar[1]
    return if start_tag == -1

    until start_tag == -1 || ret_ar[1].nil?
      cutted_line = ret_ar[1]
      finish_tag = cutted_line.index(/[ >\n]/)
      tag = cutted_line[1..finish_tag - 1]
      if !tag_was_open?(tag)
        @error_number += 1
        error_tag = @error_number.to_s + tag
        @errors.close_tag[error_tag] = "Tried to close tag '#{tag}' on line #{index} without opening"
        @index_close += 1
        @closing_tags_hash[tag] = [@index_close, index]
      elsif last_open_tag != tag
        @error_number += 1
        error_tag = @error_number.to_s + tag
        @errors.close_tag[error_tag] = "Tag must be properly nested, tried to close tag '#{tag}' on line #{index} with tag #{last_open_tag} still opened"
        remove_open_tag(tag)
        @index_open -= 1
      else
        remove_open_tag(tag)
        @index_open -= 1
      end
      cutted_line = cutted_line[1..-1]
      line = cutted_line
      ret_ar = next_close_index(line)
      start_tag = ret_ar[0]
      line = ret_ar[1]
    end
  end

  def identation(line, index)
    start_tag = line.index(/\S/)
    p "callou ident"
  end
end
