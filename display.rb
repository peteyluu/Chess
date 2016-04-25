require 'colorize'
require_relative 'cursorable'

class Display
  include Cursorable

  def initialize(board)
    @board = board
    @cursor_pos = [0, 0]
    @reachable = []
  end

  def build_grid
    @board.grid.map.with_index do |row, i|
      build_row(row, i)
    end
  end

  def build_row(row, i)
    row.each.with_index.map do |piece, j|
      color_options = colors_for(i, j)
      piece.to_s.colorize(color_options)
    end
  end

  def colors_for(i, j)
    if [i, j] == @cursor_pos
      bg = :light_red
    elsif (i + j).odd?
      if @reachable.include?([i, j])
        bg = :light_green
      else
        bg = :light_blue
      end
    else
      if @reachable.include?([i, j])
        bg = :green
      else
        bg = :blue
      end
    end
    { background: bg, color: :white}
  end

  def render
    system("clear")
    puts "Fill the grid"
    puts "Arrow keys to move, space or enter to confirm"
    puts "   " + ('a'..'h').to_a.join("    ")
    count = 8
    build_grid.each do |row|
      print "#{count}"
      print row.join
      print "#{count}\n"
      count -= 1
    end
    puts "   " + ('a'..'h').to_a.join("    ")
    @reachable = []
  end

  def reachable(moves)
    @reachable = moves
  end
end
