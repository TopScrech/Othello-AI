import ScrechKit

struct OthelloBoard: View {
    @State private var board = Array(repeating: CellState.empty, count: 64)
    
    private let rows = 8
    private let columns = 8
    
    @State private var showAlert = false
    @State private var showWarning = false
    @State private var winner: CellState?
    
    var body: some View {
        VStack {
            Text("Welcome to")
                .foregroundColor(.gray)
                .title3()
            
            Text("Othello")
                .largeTitle(.bold)
                .foregroundColor(.white)
            
            VStack {
                Text("Current Score")
                    .title3(.bold)
                    .foregroundColor(.white)
                    .offset(y: 80)
                
                HStack {
                    let scores = countPieces()
                    
                    Text("Black: \(scores.black)")
                    
                    Text("   |  ")
                    
                    Text("White: \(scores.white)")
                }
                .title2()
                .foregroundColor(.white)
                .offset(y: 85)
                
                // Game Board
                GeometryReader { geo in
                    let gridSize = min(geo.size.width, geo.size.height) * 0.9
                    let cellSize = gridSize / CGFloat(max(rows, columns))
                    
                    let xOffset = (geo.size.width - gridSize) / 2
                    let yOffset = (geo.size.height - gridSize) / 2
                    
                    ForEach(0..<64, id: \.self) { index in
                        Path { path in
                            let x = CGFloat(index % columns) * cellSize + xOffset
                            let y = CGFloat(index / columns) * cellSize + yOffset
                            let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                            path.addRect(rect)
                        }
                        .stroke(.black, lineWidth: 3)
                        .fill(.green)
                        .onTapGesture {
                            place(at: index)
                        }
                        
                        if board[index] != .empty {
                            Circle()
                                .fill(board[index] == .black ? Color.black : Color.white)
                                .frame(cellSize * 0.85)
                                .position(
                                    x: CGFloat(index % columns) * cellSize + xOffset + cellSize / 2,
                                    y: CGFloat(index / columns) * cellSize + yOffset + cellSize / 2
                                )
                        } else if validMoves().contains(index) {
                            Circle()
                                .fill(currentPlayer == .black ? Color.black.opacity(0.5) : Color.white.opacity(0.5))
                                .frame(cellSize * 0.3)
                                .position(
                                    x: CGFloat(index % columns) * cellSize + xOffset + cellSize / 2,
                                    y: CGFloat(index / columns) * cellSize + yOffset + cellSize / 2
                                )
                        } else {
                            Color.clear
                        }
                    }
                }
                .onAppear {
                    startNewgame()
                }
                .alert(winnerMessage(), isPresented: $showAlert) {
                    Button("View Board", role: .cancel) {}
                    
                    Button("Play Again", role: .destructive) {
                        startNewgame()
                    }
                }
                .padding()
            }
            
            Text("It is currently \(currentPlayer == .black ? "BLACK" : "WHITE")'s move...")
                .bold()
                .italic()
                .foregroundStyle(.white)
                .padding()
                .offset(y: -90)
            
            Button("New Game") {
                showWarning = true
            }
            .alert("Are you sure?", isPresented: $showWarning) {
                Button("New Game", role: .destructive) {
                    startNewgame()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .foregroundStyle(.white)
            .buttonStyle(.borderedProminent)
            .offset(y: -50)
        }
        .background(.black)
    }
    
    // Keep track of turns
    @State var currentPlayer: CellState = .black
    
    // Look at all 8 directions ( used in isValidMove() and flipOppPieces() )
    let directions = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
    
    func startNewgame() {
        board = Array(repeating: .empty, count: 64)
        
        // Setup board start state
        let midpoint = rows / 2
        board[(midpoint - 1) * columns + (midpoint - 1)] = .white
        board[(midpoint - 1) * columns + midpoint] = .black
        board[midpoint * columns + (midpoint - 1)] = .black
        board[midpoint * columns + midpoint] = .white
        
        currentPlayer = .black
        showAlert = false
    }
    
    func place(at index: Int) {
        // Check validity
        if isValidMove(at: index) {
            board[index] = currentPlayer
            flipOppPieces(from: index)
            
            // Switch player
            currentPlayer = currentPlayer.toggle()
            
            if isGameOver() {
                winner = isWinner()
                showAlert = true
            }
        }
    }
    
    func isValidMove(at index: Int) -> Bool {
        guard board[index] == .empty else { return false }
        
        let oppColor = currentPlayer.toggle()
        var isValid = false
        
        // Convert the index to (row, col)
        let row = index / columns
        let col = index % columns
        
        for direction in directions {
            var currentRow = row + direction.0
            var currentCol = col + direction.1
            
            // Keep track of if there is an opponent piece
            var seenOppPiece = false
            
            // While in bounds of the board
            while currentRow >= 0 && currentRow < rows && currentCol >= 0 && currentCol < columns {
                let currentIndex = currentRow * columns + currentCol
                
                // Break at an empty cell
                if board[currentIndex] == .empty { break }
                
                // At opponent piece, set seenOppPiece to true, continue
                if board[currentIndex] == oppColor {
                    seenOppPiece = true
                }
                
                // If opponent piece is found followed by current player color, move is valid
                else if seenOppPiece {
                    isValid = true
                    break
                } else {
                    // If current player's color is immediately found, it is not a valid move
                    break
                }
                
                // Check the next cell in direction
                currentRow += direction.0
                currentCol += direction.1
            }
            
            if isValid { break }
        }
        
        return isValid
    }
    
    func flipOppPieces(from index: Int) {
        let oppColor = currentPlayer.toggle()
        
        // Convert the index to (row, col)
        let row = index / columns
        let col = index % columns
        
        for direction in directions {
            var cellsToFlip: [Int] = []
            var currentRow = row + direction.0
            var currentCol = col + direction.1
            
            // While in bounds of the board
            while currentRow >= 0 && currentRow < rows && currentCol >= 0 && currentCol < columns {
                let currentIndex = currentRow * columns + currentCol
                
                // If opponent piece is seen add it to array of cells to flip
                if board[currentIndex] == oppColor {
                    cellsToFlip.append(currentIndex)
                } else if board[currentIndex] == currentPlayer {
                    // If current player's color is seen, flip collected opponent pieces
                    for flipIndex in cellsToFlip {
                        board[flipIndex] = currentPlayer
                    }
                    
                    break
                } else {
                    break
                }
                
                currentRow += direction.0
                currentCol += direction.1
            }
        }
    }
    
    func countPieces() -> (black: Int, white: Int) {
        var black = 0
        var white = 0
        
        for cell in board {
            switch cell {
            case .black: black += 1
            case .white: white += 1
            default: break
            }
        }
        
        return (black, white)
    }
    
    func isGameOver() -> Bool {
        let allIndexes = Array(board.indices)
        
        let hasMove = allIndexes.contains {
            isValidMove(at: $0)
        }
        
        return !hasMove
    }
    
    func isWinner() -> CellState? {
        let (blackCount, whiteCount) = countPieces()
        
        if blackCount > whiteCount {
            return .black
        } else if whiteCount > blackCount {
            return .white
        } else {
            return nil
        }
    }
    
    func winnerMessage() -> String {
        if let winner = isWinner() {
            "\(winner) wins!"
        } else {
            "It's a tie!"
        }
    }
    
    func validMoves() -> [Int] {
        let moves = Array(board.indices)
        
        return moves.filter {
            isValidMove(at: $0)
        }
    }
}

#Preview {
    OthelloBoard()
}
