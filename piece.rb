require 'byebug'
require 'colorize'

class Piece
  attr_reader :board, :color
  attr_accessor :pos

  def initialize(pos = nil, board = nil, color = nil)
    unless color.nil?
      @pos = pos
      @board = board
      @color = color
    end
    if self.is_a?(SlidingPieces)
      @h_delta = Hash.new { |h, k| h[k] = [] }
    end
  end

  def new_moves
    if self.is_a?(SlidingPieces)
      slidable_new_moves
    elsif self.is_a?(SteppingPieces)
      stepable_new_moves
    else
      pawn_new_moves
    end
  end

  def empty?
    self.is_a?(NullPiece)
  end

  def is_empty?(pos)
    row, col = pos
    curr_piece = @board[row][col]
    curr_piece.empty?
  end

  def ally?(pos)
    row, col = pos
    curr_piece = @board[row][col]
    curr_piece.is_ally?(@color)
  end

  def is_ally?(color)
    @color == color
  end

  def enemy?(pos)
    row, col = pos
    curr_piece = @board[row][col]
    curr_piece.is_enemy?(@color)
  end

  def is_enemy?(color)
    @color != color
  end

  private

  def pawn_new_moves
    moves = []
    deltas = move_dirs
    deltas.each do |dx, dy|
      temp_pos = [pos[0] + dx, pos[1] + dy]
      moves << temp_pos if in_bounds?(temp_pos)
    end
    filter_moves(moves)
  end

  def stepable_new_moves
    possible_moves = moves(pos)
    filter_moves(possible_moves)
  end

  def slidable_new_moves
    possible_moves = moves(pos)
    @h_delta.each do |delta_k, values_pos|
      values_pos.each do |v_pos|
        moves(v_pos, delta_k)
      end
    end
    filter_moves
    print self.color
    print self.class
    curr_moves = @h_delta.values.flatten(1).uniq
    p curr_moves
    @h_delta = Hash.new { |h, k| h[k] = [] }
    curr_moves.sort
  end

  def filter_moves(moves = nil)
    filtered_moves = []
    if moves.nil?
      @h_delta.each do |delta_k, values_pos|
        prev_enemy = nil
        values_pos.each_with_index do |v_pos, idx|
          if is_empty?(v_pos) && prev_enemy.nil?
            next
          end
          if enemy?(v_pos) && prev_enemy.nil?
            prev_enemy = true
            next
          end
          values_pos.slice!(idx..-1)
          break
        end
      end
    elsif self.is_a?(SteppingPieces)
      moves.each do |move|
        filtered_moves << move if is_empty?(move) || enemy?(move)
      end
      return filtered_moves
    elsif self.is_a?(Pawn)
      moves.each do |move|
        filtered_moves << move if valid_pawn_move?(move)
      end
      return filtered_moves
    end
  end

  def valid_pawn_move?(other_pos)
    row_i, col_i = pos
    row_j, col_j = other_pos
    if col_i == col_j
      is_empty?(other_pos)
    else
      enemy?(other_pos) && piece_in_the_way?(other_pos)
    end
  end

  def in_bounds?(pos)
    row, col = pos
    row.between?(0, 7) && col.between?(0, 7)
  end

  def piece_in_the_way?(pos)
    row, col = pos
    return false if @board[row][col].is_a?(NullPiece)
    true
  end

  def deep_dup(array)
    a = []
    array.each do |el|
      if el.is_a?(Array)
        a << deep_dup(el)
      else
        a << el
      end
    end
    a
  end
end

class NullPiece < Piece
  def to_s
    img = "     "
  end
end

class SlidingPieces < Piece
  def moves(pos_val, delta_key = nil)
    moves = []
    if delta_key.nil?
      one_moves_away = move_dirs
      curr_pos = pos_val
      one_moves_away.each do |dx, dy|
        curr_delta = [dx, dy]
        temp_curr_pos = [curr_pos[0] + dx, curr_pos[1] + dy]
        if in_bounds?(temp_curr_pos)
          @h_delta[curr_delta] << temp_curr_pos
          moves << temp_curr_pos
        end
      end
    else
      curr_pos = pos_val
      dx, dy = delta_key
      temp_curr_pos = [curr_pos[0] + dx, curr_pos[1] + dy]
      if in_bounds?(temp_curr_pos)
        @h_delta[delta_key] << temp_curr_pos
        moves << temp_curr_pos
      end
    end
    moves
  end
end

class SteppingPieces < Piece
  def moves(pos)
    moves = []
    one_moves_away = move_dirs
    curr_pos = pos
    one_moves_away.each do |dx, dy|
      temp_curr_pos = [curr_pos[0] + dx, curr_pos[1] + dy]
      moves << temp_curr_pos if in_bounds?(temp_curr_pos)
    end
    moves
  end
end

class Pawn < Piece
  def move_dirs
    if self.color == :black
      row, col = self.pos
      if row == 1
        [[1, 0], [2, 0], [1, -1], [1, 1]]
      else
        [[1, 0], [1, -1], [1, 1]]
      end
    else
      row, col = self.pos
      if row == 6
        [[-1, 0], [-2, 0], [-1, -1], [-1, 1]]
      else
        [[-1, 0], [-1, -1], [-1, 1]]
      end
    end
  end

  def to_s
    img = @color == :black ? '  ♟  ' : '  ♙  '
  end
end

class Rook < SlidingPieces
  def move_dirs
    [[-1, 0], [1, 0], [0, -1], [0, 1]]
  end

  def to_s
    img = @color == :black ? '  ♜  ' : '  ♖  '
  end
end

class Knight < SteppingPieces
  def move_dirs
    [[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]]
  end

  def to_s
    img = @color == :black ? '  ♞  ' : '  ♘  '
  end
end

class Bishop < SlidingPieces
  def move_dirs
    [[-1, -1], [-1, 1], [1, -1], [1, 1]]
  end

  def to_s
    img = @color == :black ? '  ♝  ' : '  ♗  '
  end
end

class Queen < SlidingPieces
  def move_dirs
    [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]]
  end

  def to_s
    img = @color == :black ? '  ♛  ' : '  ♕  '
  end
end

class King < SteppingPieces
  def move_dirs
    [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]]
  end

  def to_s
    img = @color == :black ? '  ♚  ' : '  ♔  '
  end
end
