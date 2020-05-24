module ValidateAngleBrackets
  def check_angle_brackets(line, index)
    bracket_stack = []
    line.split('').each_with_index do |n, i|
      if n == '<'
        if bracket_stack.size.zero?
          bracket_stack.push(n)
        else
          create_error_bracket_inside(index, i)
          return nil
        end
      end
      bracket_stack.pop if n == '>' && bracket_stack.size == 1
    end
    create_error_bracket_unclosed(index) unless bracket_stack.size.zero?
  end

  def create_error_bracket_inside(index, col)
    @error_number += 1
    @errors.angle_bracket.push("Line #{index} with angle bracket(<) open inside another angle bracket at col #{col}")
  end

  def create_error_bracket_unclosed(index)
    @error_number += 1
    @errors.angle_bracket.push("Line #{index} should have all angle brackets(<) closed with a matchin (>)")
  end
end
