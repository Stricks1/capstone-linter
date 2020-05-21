class ErrorFound
    attr_accessor :ident, :open_tag, :close_tag, :invalid_prop


    def initialize
        @ident = Hash.new(0)
        @open_tag = Hash.new(0)
        @close_tag = Hash.new(0)
        @invalid_prop = Hash.new(0)
    end
end