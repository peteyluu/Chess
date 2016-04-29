require 'byebug'
require_relative 'piece'

class Board
  attr_reader :grid
  PIECES = ["queen", "rook", "bishop", "knight"]

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
      promote_piece(get_input, end_pos, curr_piece.color)
    else
      curr_piece.pos = end_pos
    end

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

  def check_mate?(color)
    moves = []
    if in_check?(color)
      curr_pieces = pieces.select { |piece| piece.color == color }
      curr_pieces.each do |piece|
        piece.new_moves.each do |move|
          if !move_into_check?(piece.pos, move, color)
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
    when "queen"
      @grid[row][col] = Queen.new(piece_pos, self, piece_color)
    when "rook"
      @grid[row][col] = Rook.new(piece_pos, self, piece_color)
    when "bishop"
      @grid[row][col] = Bishop.new(piece_pos, self, piece_color)
    when "knight"
      @grid[row][col] = Knight.new(piece_pos, self, piece_color)
    else
      puts "Only queens, rooks, bishops, knights allowed!"
    end
  end

  def get_input
    print "Which piece would you like to promote? (i.e. queen) "
    input = ""
    until PIECES.include?(input)
      input = gets.chomp
    end
    input
  end

  def setup_pieces
    setup_back_row
    setup_pawns
  end

  def setup_back_row
    setup_kings
    setup_queens
    setup_bishops
    setup_knights
    setup_rooks
  end

  def setup_kings
    @grid[0][4] = King.new([0, 4], self, :black)
    @grid[7][4] = King.new([7, 4], self, :white)
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
    @grid[0][0] = Rook.new([0, 0], self, :black)
    @grid[0][7] = Rook.new([0, 7], self, :black)
    @grid[7][0] = Rook.new([7, 0], self, :white)
    @grid[7][7] = Rook.new([7, 7], self, :white)
  end

  def setup_pawns
    8.times do |i|
      @grid[1][i] = Pawn.new([1, i], self, :black)
      @grid[6][i] = Pawn.new([6, i], self, :white)
    end
  end
end
