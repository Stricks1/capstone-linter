class ErrorFound
  attr_accessor :ident, :open_tag, :close_tag, :angle_bracket

  def initialize
    @angle_bracket = []
    @ident = []
    @open_tag = Hash.new(0)
    @close_tag = Hash.new(0)
  end
end
