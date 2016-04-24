require_relative 'display'

class Player
  attr_reader :color, :display

  def initialize(color, display)
    @color = color
    @display = display
  end
end

class HumanPlayer < Player
  def make_move
    start_pos, end_pos = nil, nil
    until start_pos && end_pos
      display.render
      if start_pos
        puts "#{color}'s turn. Move to where?"
        end_pos = display.get_input
      else
        puts "#{color}'s turn. Move from where?"
        start_pos = display.get_input
      end
    end
    [start_pos, end_pos]
  end
end
