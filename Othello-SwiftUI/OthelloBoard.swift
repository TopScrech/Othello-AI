import Foundation
import ScrechKit

struct OthelloBoard: View {
    enum GameMode: String, CaseIterable, Identifiable {
        case humanVsHuman = "Human vs Human",
             humanVsAI = "Human vs AI",
             aiVsAI = "AI vs AI"
        
        var id: String { rawValue }
    }

    enum AIType: String, CaseIterable, Identifiable {
        case classic = "Classic (Depth)"
        case timed = "Timed (Seconds)"

        var id: String { rawValue }
    }
    
    @State private var board = Array(repeating: CellState.empty, count: 64)
    
    private let rows = 8
    private let columns = 8
    
    @State private var showAlert = false
    @State private var showWarning = false
    @State private var winner: CellState?
    
    @State private var currentPlayer: CellState = .black
    
    @State private var gameMode: GameMode = .humanVsAI
    @State private var aiPlayer: CellState = .white
    @State private var aiDepth = 3
    @State private var aiTimeSeconds = 9
    @State private var aiType: AIType = .timed
    @State private var aiBlackType: AIType = .classic
    @State private var aiWhiteType: AIType = .timed
    @State private var maxThinkTimeBlack: Double = 0
    @State private var maxThinkTimeWhite: Double = 0
    @State private var isAIMoving = false
    @State private var gameId = 0
    
    
    var body: some View {
        VStack {
            Text("Welcome to")
                .foregroundColor(.gray)
                .title3()
            
            Text("Othello")
                .largeTitle(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                Picker("Mode", selection: $gameMode) {
                    ForEach(GameMode.allCases) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                
                if gameMode == .humanVsAI {
                    Picker("AI Plays", selection: $aiPlayer) {
                        Text("Black").tag(CellState.black)
                        Text("White").tag(CellState.white)
                    }
                    .pickerStyle(.segmented)

                    Picker("AI Type", selection: $aiType) {
                        ForEach(AIType.allCases) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)

                    if aiType == .classic {
                        Stepper("AI Depth: \(aiDepth)", value: $aiDepth, in: 1...10)
                            .foregroundColor(.white)
                    } else {
                        Stepper("AI Time: \(aiTimeSeconds)s", value: $aiTimeSeconds, in: 1...30)
                            .foregroundColor(.white)
                    }
                }

                if gameMode == .aiVsAI {
                    VStack(spacing: 8) {
                        Picker("Black AI", selection: $aiBlackType) {
                            ForEach(AIType.allCases) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("White AI", selection: $aiWhiteType) {
                            ForEach(AIType.allCases) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack {
                            Stepper("Depth: \(aiDepth)", value: $aiDepth, in: 1...10)
                                .foregroundColor(.white)
                            Stepper("Time: \(aiTimeSeconds)s", value: $aiTimeSeconds, in: 1...30)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            .onChange(of: gameMode) {
                startNewgame()
            }
            .onChange(of: aiPlayer) {
                startNewgame()
            }
            .onChange(of: aiType) {
                startNewgame()
            }
            .onChange(of: aiBlackType) {
                startNewgame()
            }
            .onChange(of: aiWhiteType) {
                startNewgame()
            }
            
            VStack {
                Text("Current Score")
                    .title3(.bold)
                    .foregroundColor(.white)
                    .offset(y: 80)
                
                HStack {
                    let scores = countPieces(on: board)
                    
                    Text("Black: \(scores.black)")
                    
                    Text("   |  ")
                    
                    Text("White: \(scores.white)")
                }
                .title2()
                .foregroundColor(.white)
                .offset(y: 85)

                HStack {
                    Text("Max Think")
                    Text("B \(timeString(maxThinkTimeBlack))")
                    Text(" | ")
                    Text("W \(timeString(maxThinkTimeWhite))")
                }
                .title3()
                .foregroundColor(.white.opacity(0.9))
                .offset(y: 85)
                
                GeometryReader { geo in
                    let gridSize = min(geo.size.width, geo.size.height) * 0.9
                    let cellSize = gridSize / CGFloat(max(rows, columns))
                    
                    let xOffset = (geo.size.width - gridSize) / 2
                    let yOffset = (geo.size.height - gridSize) / 2
                    let currentValidMoves = validMoves(for: currentPlayer, on: board)
                    
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
                            guard isHumanTurn else { return }
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
                        } else if currentValidMoves.contains(index) {
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
                    Button("Play Again", role: .destructive, action: startNewgame)
                }
                .padding()
            }
            
            Text("It is currently \(currentPlayer.displayName)'s move...")
                .bold()
                .italic()
                .foregroundStyle(.white)
                .padding()
                .offset(y: -90)
            
            Button("New Game") {
                showWarning = true
            }
            .alert("Are you sure?", isPresented: $showWarning) {
                Button("New Game", role: .destructive, action: startNewgame)
                Button("Cancel", role: .cancel) {}
            }
            .foregroundStyle(.white)
            .buttonStyle(.borderedProminent)
            .offset(y: -50)
        }
        .background(.black)
    }
    
    private var isHumanTurn: Bool {
        switch gameMode {
        case .humanVsHuman: true
        case .humanVsAI: currentPlayer != aiPlayer
        case .aiVsAI: false
        }
    }
    
    private var isAITurn: Bool {
        switch gameMode {
        case .humanVsHuman: false
        case .humanVsAI: currentPlayer == aiPlayer
        case .aiVsAI: true
        }
    }

    private func aiType(for player: CellState) -> AIType {
        switch gameMode {
        case .humanVsAI:
            return aiType
        case .aiVsAI:
            return player == .black ? aiBlackType : aiWhiteType
        case .humanVsHuman:
            return .classic
        }
    }
    
    func startNewgame() {
        board = Array(repeating: .empty, count: 64)
        
        let midpoint = rows / 2
        board[(midpoint - 1) * columns + (midpoint - 1)] = .white
        board[(midpoint - 1) * columns + midpoint] = .black
        board[midpoint * columns + (midpoint - 1)] = .black
        board[midpoint * columns + midpoint] = .white
        
        currentPlayer = .black
        showAlert = false
        winner = nil
        isAIMoving = false
        gameId += 1
        maxThinkTimeBlack = 0
        maxThinkTimeWhite = 0
        triggerAIMoveIfNeeded()
    }
    
    func place(at index: Int) {
        applyMove(at: index, player: currentPlayer)
    }
    
    func applyMove(at index: Int, player: CellState) {
        guard isValidMove(at: index, player: player, on: board) else { return }
        board = boardAfterMove(at: index, player: player, on: board)
        currentPlayer = player.toggle()
        postMove()
    }
    
    func postMove() {
        resolveNoMoves()
        if showAlert { return }
        triggerAIMoveIfNeeded()
    }
    
    func resolveNoMoves() {
        guard !hasAnyMove(for: currentPlayer, on: board) else { return }
        let otherPlayer = currentPlayer.toggle()
        
        if hasAnyMove(for: otherPlayer, on: board) {
            currentPlayer = otherPlayer
        } else {
            finishGame()
        }
    }
    
    func finishGame() {
        winner = winnerFor(board)
        showAlert = true
    }
    
    func triggerAIMoveIfNeeded() {
        guard !showAlert else { return }
        resolveNoMoves()
        guard !showAlert else { return }
        guard isAITurn else { return }
        guard !isAIMoving else { return }
        
        let currentGameId = gameId
        let player = currentPlayer
        let depth = aiDepth
        let timeSeconds = aiTimeSeconds
        let selectedAIType = aiType(for: player)
        let boardSnapshot = board
        
        isAIMoving = true
        
        Task.detached {
            try? await Task.sleep(nanoseconds: 250_000_000)
            let startTime = DispatchTime.now().uptimeNanoseconds
            let move: Int?

            switch selectedAIType {
            case .classic:
                move = await OthelloEngine.bestMoveParallel(for: player, depth: depth, on: boardSnapshot)
            case .timed:
                move = await OthelloEngine.bestMoveTimed(for: player, on: boardSnapshot, seconds: TimeInterval(timeSeconds))
            }
            let elapsedSeconds = Double(DispatchTime.now().uptimeNanoseconds - startTime) / 1_000_000_000

            await MainActor.run {
                guard currentGameId == gameId else {
                    isAIMoving = false
                    return
                }
                
                guard currentPlayer == player else {
                    isAIMoving = false
                    return
                }

                isAIMoving = false
                updateMaxThinkTime(for: player, elapsed: elapsedSeconds)

                if let move {
                    applyMove(at: move, player: player)
                } else {
                    currentPlayer = player.toggle()
                    postMove()
                }
            }
        }
    }
    
    func validMoves(for player: CellState, on board: [CellState]) -> [Int] {
        let position = OthelloEngine.position(from: board)
        let moves = OthelloEngine.legalMoves(player: player, position: position)
        return OthelloEngine.moveIndices(from: moves)
    }
    
    func hasAnyMove(for player: CellState, on board: [CellState]) -> Bool {
        let position = OthelloEngine.position(from: board)
        return OthelloEngine.legalMoves(player: player, position: position) != 0
    }
    
    func isValidMove(at index: Int, player: CellState, on board: [CellState]) -> Bool {
        let position = OthelloEngine.position(from: board)
        return OthelloEngine.isValidMove(index: index, player: player, position: position)
    }
    
    func boardAfterMove(at index: Int, player: CellState, on board: [CellState]) -> [CellState] {
        let position = OthelloEngine.position(from: board)
        let next = OthelloEngine.applying(moveIndex: index, player: player, position: position)
        return OthelloEngine.board(from: next)
    }
    
    func countPieces(on board: [CellState]) -> (black: Int, white: Int) {
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
    
    func winnerFor(_ board: [CellState]) -> CellState? {
        let counts = countPieces(on: board)
        
        if counts.black > counts.white {
            return .black
        }
        
        if counts.white > counts.black {
            return .white
        }
        
        return nil
    }
    
    func winnerMessage() -> String {
        if let winner {
            "\(winner.displayName) wins!"
        } else {
            "It's a tie!"
        }
    }
    
    private func updateMaxThinkTime(for player: CellState, elapsed: Double) {
        if player == .black {
            maxThinkTimeBlack = max(maxThinkTimeBlack, elapsed)
        } else if player == .white {
            maxThinkTimeWhite = max(maxThinkTimeWhite, elapsed)
        }
    }

    private func timeString(_ seconds: Double) -> String {
        String(format: "%.2fs", seconds)
    }
}

#Preview {
    OthelloBoard()
}
