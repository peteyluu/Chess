require 'byebug'
require_relative 'dummy_piece'

class Board
  attr_reader :grid

  def self.init_board
    Array.new(8) { Array.new(8, NullPiece.new) }
  end

  def initialize(fill_board = true)
    @grid = Board.init_board
    populate if fill_board == true
  end

  def populate
    setup_pieces
  end

  def move(turn_color, start_pos, end_pos)
    row_i, col_i = start_pos
    if @grid[row_i][col_i].empty?
      raise "There is no piece at start!"
    end

    curr_piece = @grid[row_i][col_i]
    if curr_piece.color != turn_color
      raise "You must move your own piece!"
    elsif !curr_piece.new_moves.include?(end_pos)
      raise "Piece can't move there!"
    elsif move_into_check?(start_pos, end_pos, turn_color)
      raise "You cannot move when you are in check!"
    end

    move!(start_pos, end_pos)
  end

  def move!(start_pos, end_pos)
    curr_piece = self[start_pos]

    self[end_pos] = curr_piece
    row, col = end_pos

    if self[end_pos].is_a?(Pawn) && (row == 0 || row == 7)
      input = get_input
      promote_piece(input, end_pos, curr_piece.color)
    else
      curr_piece.pos = end_pos
    end

    if self[end_pos].is_a?(Rook)
      self[end_pos].moved = true
    end

    diff_col = (start_pos[1] - end_pos[1]).abs

    if self[end_pos].is_a?(King) && self[start_pos].moved == false && diff_col == 2 && (row == 0 || row == 7)
      temp_rooks = find_rooks(curr_piece.color)

      curr_rook = nil
      new_rook_pos = nil
      diff_col = start_pos[1] + end_pos[1]
      if diff_col == 6
        diff_col /= 2
        if curr_piece.color == :black
          curr_rook = temp_rooks.find { |rook| rook.pos == [0, 0] }
          new_rook_pos = [0, diff_col]
        else
          curr_rook = temp_rooks.find { |rook| rook.pos == [7, 0] }
          new_rook_pos = [7, diff_col]
        end
      elsif diff_col == 10
        diff_col /= 2
        if curr_piece.color == :black
          curr_rook = temp_rooks.find { |rook| rook.pos == [0, 7] }
          new_rook_pos = [0, diff_col]
        else
          curr_rook = temp_rooks.find { |rook| rook.pos == [7, 7] }
          new_rook_pos = [7, diff_col]
        end
      end
      prev_pos = curr_rook.pos
      curr_rook_piece = self[curr_rook.pos]
      self[new_rook_pos] = curr_rook_piece
      curr_rook_piece.pos = new_rook_pos
      curr_rook_piece.moved = true
      self[prev_pos] = NullPiece.new
    end
    self[end_pos].moved = true

    self[start_pos] = NullPiece.new
  end

  def in_check?(color)
    king_pos = find_king(color).pos
    pieces.each do |piece|
      if piece.color != color && piece.new_moves.include?(king_pos)
        return true
      end
    end
    false
  end

  def move_into_check?(start_pos, end_pos, color)
    new_board = self.dup
    new_board.move!(start_pos, end_pos)
    new_board.in_check?(color)
  end

  def move_thru_check?(start_pos, end_pos, color)
    row, col = end_pos
    opponent_pieces = pieces.select { |piece| piece.color != color }
    if col > 4
      temp_pos = [row, col - 1]
      return false if opponent_pieces.any? { |piece| piece.new_moves.include?(temp_pos) }
    else
      temp_pos = [row, col + 1]
      return false if opponent_pieces.any? { |piece| piece. new_moves.include?(temp_pos) }
    end
    true
  end

  def check_mate?(color)
    moves = []
    if in_check?(color)
      curr_pieces = pieces.select { |piece| piece.color == color }
      curr_pieces.each do |piece|
        piece.new_moves.each do |move|
          curr_piece_pos = piece.pos
          if !move_into_check?(curr_piece_pos, move, color)
            moves << move
          end
        end
      end
      return true if moves.empty?
    end
    false
  end

  def in_bounds?(pos)
    row, col = pos
    row.between?(0, 7) && col.between?(0, 7)
  end

  def []=(pos, piece_obj)
    row, col = pos
    @grid[row][col] = piece_obj
  end

  def [](pos)
    row, col = pos
    @grid[row][col]
  end

  def get_new_moves_from_piece(piece)
    piece.new_moves
  end

  def get_piece(pos)
    row, col = pos
    return @grid[row][col]
  end

  def dup
    test_board = Board.new(false)
    pieces.each do |piece|
      new_piece = piece.class.new(piece.pos, test_board, piece.color)
      test_board.add_piece(new_piece, new_piece.pos)
    end
    test_board
  end

  def add_piece(piece_obj, piece_pos)
    row, col = piece_pos
    self[piece_pos] = piece_obj
  end

  private

  def find_rooks(color)
    found_rooks = []
    found_rooks = pieces.select { |piece| piece.is_a?(Rook) && piece.color == color && piece.moved == false }
  end

  def find_king(color)
    curr_pieces = pieces
    curr_king = curr_pieces.find { |piece| piece.is_a?(King) && piece.color == color }
    return curr_king if curr_king.is_a?(King)
    raise 'King not found!'
  end

  def pieces
    @grid.flatten.select { |piece| !piece.empty? }
  end

  def promote_piece(piece_str, piece_pos, piece_color)
    row, col = piece_pos
    case piece_str
    when "promote"
      @grid[row][col] = Queen.new(piece_pos, self, piece_color)
    when "unpromote"
      @grid[row][col] = Knight.new(piece_pos, self, piece_color)
    end
  end

  def get_input
    print "Would you like to promote or unpromote? (i.e. promote) "
    input = gets.chomp
    input.downcase!
    until input == "promote" || input == "unpromote"
      input = gets.chomp
      input.downcase!
    end
    input
  end

  def setup_pieces
    setup_castling
    # setup_back_row
    # setup_pawns
  end

  def setup_castling
    @grid[0][4] = King.new([0, 4], self, :black, false)
    @grid[7][4] = King.new([7, 4], self, :white, false)
    @grid[0][0] = Rook.new([0, 0], self, :black, false)
    @grid[0][7] = Rook.new([0, 7], self, :black, false)
    @grid[7][0] = Rook.new([7, 0], self, :white, false)
    @grid[7][7] = Rook.new([7, 7], self, :white, false)
    # @grid[7][5] = Bishop.new([7, 5], self, :white)
    # @grid[0][2] = Bishop.new([0, 2], self, :black)
    # @grid[5][0] = Queen.new([5, 0], self, :white)
    # @grid[2][0] = Queen.new([2, 0], self, :black)
    # @grid[4][7] = Bishop.new([4, 7], self, :white)
    # @grid[3][7] = Bishop.new([3, 7], self, :black)
    # @grid[1][1] = Pawn.new([1, 1], self, :black)
    # @grid[6][0] = Pawn.new([6, 0], self, :white)

    @grid[0][3] = Queen.new([0, 3], self, :black)
    @grid[7][3] = Queen.new([7, 3], self, :white)
  end

  def setup_back_row
    setup_kings
    setup_queens
    setup_bishops
    setup_knights
    setup_rooks
  end

  def setup_kings
    @grid[0][4] = King.new([0, 4], self, :black, false)
    @grid[7][4] = King.new([7, 4], self, :white, false)
  end

  def setup_queens
    @grid[0][3] = Queen.new([0, 3], self, :black)
    @grid[7][3] = Queen.new([7, 3], self, :white)
  end

  def setup_bishops
    @grid[0][2] = Bishop.new([0, 2], self, :black)
    @grid[0][5] = Bishop.new([0, 5], self, :black)
    @grid[7][2] = Bishop.new([7, 2], self, :white)
    @grid[7][5] = Bishop.new([7, 5], self, :white)
  end

  def setup_knights
    @grid[0][1] = Knight.new([0, 1], self, :black)
    @grid[0][6] = Knight.new([0, 6], self, :black)
    @grid[7][1] = Knight.new([7, 1], self, :white)
    @grid[7][6] = Knight.new([7, 6], self, :white)
  end

  def setup_rooks
    @grid[0][0] = Rook.new([0, 0], self, :black, false)
    @grid[0][7] = Rook.new([0, 7], self, :black, false)
    @grid[7][0] = Rook.new([7, 0], self, :white, false)
    @grid[7][7] = Rook.new([7, 7], self, :white, false)
  end

  def setup_pawns
    8.times do |i|
      @grid[1][i] = Pawn.new([1, i], self, :black)
      @grid[6][i] = Pawn.new([6, i], self, :white)
    end
  end
end
