require 'byebug'
require_relative 'piece'

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

  # How do I write a method to check if the current piece/player is in check??
  def move(turn_color, start_pos, end_pos)
    row_i, col_i = start_pos
    if @grid[row_i][col_i].empty?
      raise "There is no piece at start"
    end

    curr_piece = @grid[row_i][col_i]
    if curr_piece.color != turn_color
      raise "You must move your own piece"
    elsif !curr_piece.new_moves.include?(end_pos)
      raise "Piece can't move there"
    elsif in_check?(turn_color)
      raise "You cannot move when you are in check"
    end

    move!(start_pos, end_pos)
  end

  # But #valid_moves needs to make a move on a duped board to see if a player is left in check. For this reason, write a method Board#move! which makes a move without checking if it is valid.
  def move!(start_pos, end_pos)
    curr_piece = self[start_pos]
    # raise "piece cannot move there!" unless curr_piece.new_moves.include?(end_pos)

    self[end_pos] = curr_piece
    row, col = end_pos
    if self[end_pos].is_a?(Pawn) && (row == 0 || row == 7)
      input = get_input
      revive_piece(input, end_pos, curr_piece.color)
    else
      curr_piece.pos = end_pos
    end
    self[start_pos] = NullPiece.new(start_pos)
  end

  # the board class should have a method #in_check?(color) that returns whether a player is in check. You can implement this by
  # 1) finding the position of the king on the board THEN
  # 2) seeing if any of the opposing pieces can move to that position.
  def in_check?(color)
    # debugger
    king_pos = find_king(color).pos
    pieces.each do |piece|
      if piece.color != color && piece.new_moves.include?(king_pos)
        return true
      end
    end
    false
  end

  # If the player is in check, and if none of the player's pieces have any #valid_moves, then the player is in checkmate.

  # Piece#valid_moves
  # You want a method on Piece that filters out the #moves of a Piece that would leave the player in check.
  # A good approach is to write a Piece#move_into_check?(pos) method that will:
  # 1) Dup the Board and perform the move.
  # 2) Look to see if the player is in check after the move (Board#in_check?)

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

  # # how do i protect the King, when it is Board#in_check?
  # # S1: The king can move to other positions if available...
  # # S2: The path can be blocked, preventing the king Board#in_check?/check_mate?
  # # S3:
  # def filter_king_moves(king_moves, color)
  #   moves = []
  #   king_moves.each do |king_move|
  #     unless pieces.any? { |piece| piece.color != color && piece.new_moves.include?(king_move) }
  #       moves << king_move
  #     end
  #     # can protect the king from harm....?
  #     # !pieces.any? { |piece| piece.color == color && piece.new_moves.include?(king_move) }
  #     #   moves << king_move
  #   end
  #   moves
  # end

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
    debugger
    @grid[row][col]
  end

  def dup
    # debugger
    test_board = Board.new(false)
    pieces.each do |piece|
      new_piece = piece.class.new(piece.pos, test_board, piece.color)
      test_board.add_piece(new_piece, new_piece.pos)
      # row, col = new_piece.pos
      # test_board[row][col] = new_piece
    end
    # 8.times do |i|
    #   8.times do |j|
    #     curr_piece = test_board[i][j]
    #     next if curr_piece.empty?
    #     new_piece = curr_piece.class.new(curr_piece.pos, test_board, curr_piece.color)
    #     test_board.add_piece(new_piece, new_piece.pos)
    #   end
    # end
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

  def revive_piece(piece_str, piece_pos, piece_color)
    row, col = piece_pos
    case piece_str
    when "queen"
      @grid[row][col] = Queen.new(piece_pos, @grid, piece_color)
    when "rook"
      @grid[row][col] = Rook.new(piece_pos, @grid, piece_color)
    when "bishop"
      @grid[row][col] = Bishop.new(piece_pos, @grid, piece_color)
    when "knight"
      @grid[row][col] = Knight.new(piece_pos, @grid, piece_color)
    end
  end

  def get_input
    pieces = ["queen", "rook", "bishop", "knight"]
    print "What piece would you like to bring back from the dead? (i.e. queen) "
    input = gets.chomp
    input.downcase!
    until pieces.include?(input)
      input = gets.chomp
      input.downcase!
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
    @grid[0][4] = King.new([0, 4], @grid, :black)
    @grid[7][4] = King.new([7, 4], @grid, :white)
  end

  def setup_queens
    @grid[0][3] = Queen.new([0, 3], @grid, :black)
    @grid[7][3] = Queen.new([7, 3], @grid, :white)
  end

  def setup_bishops
    @grid[0][2] = Bishop.new([0, 2], @grid, :black)
    @grid[0][5] = Bishop.new([0, 5], @grid, :black)
    @grid[7][2] = Bishop.new([7, 2], @grid, :white)
    @grid[7][5] = Bishop.new([7, 5], @grid, :white)
  end

  def setup_knights
    @grid[0][1] = Knight.new([0, 1], @grid, :black)
    @grid[0][6] = Knight.new([0, 6], @grid, :black)
    @grid[7][1] = Knight.new([7, 1], @grid, :white)
    @grid[7][6] = Knight.new([7, 6], @grid, :white)
  end

  def setup_rooks
    @grid[0][0] = Rook.new([0, 0], @grid, :black)
    @grid[0][7] = Rook.new([0, 7], @grid, :black)
    @grid[7][0] = Rook.new([7, 0], @grid, :white)
    @grid[7][7] = Rook.new([7, 7], @grid, :white)
  end

  def setup_pawns
    8.times do |i|
      @grid[1][i] = Pawn.new([1, i], @grid, :black)
      @grid[6][i] = Pawn.new([6, i], @grid, :white)
    end
  end
end

# if __FILE__ == $PROGRAM_NAME
#   b = Board.new
# end
