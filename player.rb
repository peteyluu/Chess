require 'byebug'
require_relative 'display'

class Player
  attr_reader :color, :display

  def initialize(color, display)
    @color = color
    @display = display
  end
end

class HumanPlayer < Player
  def make_move(board)
    start_pos, end_pos = nil, nil
    until start_pos && end_pos
      # debugger
      display.render
      if start_pos
        curr_piece = board.get_piece(start_pos)
        moves = board.get_new_moves_from_piece(curr_piece)
        display.reachable(moves)
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
