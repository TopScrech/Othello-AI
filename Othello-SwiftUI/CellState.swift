enum CellState: Hashable {
    case empty, black, white
    
    func toggle() -> CellState {
        switch self {
        case.black: .white
        case.white: .black
        default: .empty
        }
    }

    var displayName: String {
        switch self {
        case .black: "BLACK"
        case .white: "WHITE"
        case .empty: "EMPTY"
        }
    }
}

extension CellState: Sendable {}

struct OthelloEngine {
    static let positionWeights: [Int] = [
        120, -20, 20, 5, 5, 20, -20, 120,
        -20, -40, -5, -5, -5, -5, -40, -20,
        20, -5, 15, 3, 3, 15, -5, 20,
        5, -5, 3, 3, 3, 3, -5, 5,
        5, -5, 3, 3, 3, 3, -5, 5,
        20, -5, 15, 3, 3, 15, -5, 20,
        -20, -40, -5, -5, -5, -5, -40, -20,
        120, -20, 20, 5, 5, 20, -20, 120
    ]
    
    static let moveOrder: [Int] = {
        (0..<64).sorted { positionWeights[$0] > positionWeights[$1] }
    }()
    
    static let notA: UInt64 = 0xfefefefefefefefe
    static let notH: UInt64 = 0x7f7f7f7f7f7f7f7f
    static let corners: UInt64 = 0x8100000000000081
    
    struct Position: Hashable, Sendable {
        var black: UInt64
        var white: UInt64
    }
    
    @inline(__always)
    static func bit(_ index: Int) -> UInt64 {
        UInt64(1) << UInt64(index)
    }
    
    static func position(from board: [CellState]) -> Position {
        var black: UInt64 = 0
        var white: UInt64 = 0
        
        for (index, cell) in board.enumerated() {
            switch cell {
            case .black:
                black |= bit(index)
            
            case .white:
                white |= bit(index)
            
            default:
                break
            }
        }
        
        return Position(black: black, white: white)
    }
    
    static func board(from position: Position) -> [CellState] {
        var board = Array(repeating: CellState.empty, count: 64)
        
        for index in 0..<64 {
            let b = bit(index)
            
            if (position.black & b) != 0 {
                board[index] = .black
            } else if (position.white & b) != 0 {
                board[index] = .white
            }
        }
        
        return board
    }
    
    @inline(__always)
    static func shiftN(_ bb: UInt64) -> UInt64 { bb >> 8 }
    
    @inline(__always)
    static func shiftS(_ bb: UInt64) -> UInt64 { bb << 8 }
    
    @inline(__always)
    static func shiftE(_ bb: UInt64) -> UInt64 { (bb & notH) << 1 }
    
    @inline(__always)
    static func shiftW(_ bb: UInt64) -> UInt64 { (bb & notA) >> 1 }
    
    @inline(__always)
    static func shiftNE(_ bb: UInt64) -> UInt64 { (bb & notH) >> 7 }
    
    @inline(__always)
    static func shiftNW(_ bb: UInt64) -> UInt64 { (bb & notA) >> 9 }
    
    @inline(__always)
    static func shiftSE(_ bb: UInt64) -> UInt64 { (bb & notH) << 9 }
    
    @inline(__always)
    static func shiftSW(_ bb: UInt64) -> UInt64 { (bb & notA) << 7 }
    
    @inline(__always)
    static func masks(for player: CellState, in position: Position) -> (me: UInt64, opp: UInt64) {
        switch player {
        case .black:
            (position.black, position.white)
            
        case .white:
            (position.white, position.black)
            
        default:
            (0, 0)
        }
    }
    
    @inline(__always)
    static func legalMoves(player: CellState, position: Position) -> UInt64 {
        let (me, opp) = masks(for: player, in: position)
        let empty = ~(me | opp)
        
        var moves: UInt64 = 0
        var t: UInt64
        
        t = opp & shiftN(me)
        t |= opp & shiftN(t)
        t |= opp & shiftN(t)
        t |= opp & shiftN(t)
        t |= opp & shiftN(t)
        t |= opp & shiftN(t)
        moves |= empty & shiftN(t)
        
        t = opp & shiftS(me)
        t |= opp & shiftS(t)
        t |= opp & shiftS(t)
        t |= opp & shiftS(t)
        t |= opp & shiftS(t)
        t |= opp & shiftS(t)
        moves |= empty & shiftS(t)
        
        t = opp & shiftE(me)
        t |= opp & shiftE(t)
        t |= opp & shiftE(t)
        t |= opp & shiftE(t)
        t |= opp & shiftE(t)
        t |= opp & shiftE(t)
        moves |= empty & shiftE(t)
        
        t = opp & shiftW(me)
        t |= opp & shiftW(t)
        t |= opp & shiftW(t)
        t |= opp & shiftW(t)
        t |= opp & shiftW(t)
        t |= opp & shiftW(t)
        moves |= empty & shiftW(t)
        
        t = opp & shiftNE(me)
        t |= opp & shiftNE(t)
        t |= opp & shiftNE(t)
        t |= opp & shiftNE(t)
        t |= opp & shiftNE(t)
        t |= opp & shiftNE(t)
        moves |= empty & shiftNE(t)
        
        t = opp & shiftNW(me)
        t |= opp & shiftNW(t)
        t |= opp & shiftNW(t)
        t |= opp & shiftNW(t)
        t |= opp & shiftNW(t)
        t |= opp & shiftNW(t)
        moves |= empty & shiftNW(t)
        
        t = opp & shiftSE(me)
        t |= opp & shiftSE(t)
        t |= opp & shiftSE(t)
        t |= opp & shiftSE(t)
        t |= opp & shiftSE(t)
        t |= opp & shiftSE(t)
        moves |= empty & shiftSE(t)
        
        t = opp & shiftSW(me)
        t |= opp & shiftSW(t)
        t |= opp & shiftSW(t)
        t |= opp & shiftSW(t)
        t |= opp & shiftSW(t)
        t |= opp & shiftSW(t)
        moves |= empty & shiftSW(t)
        
        return moves
    }
    
    @inline(__always)
    static func flippedDiscs(move: UInt64, me: UInt64, opp: UInt64) -> UInt64 {
        var flips: UInt64 = 0
        var captured: UInt64
        var m: UInt64
        
        captured = 0
        m = shiftN(move)
        
        while m != 0 && (m & opp) != 0 {
            captured |= m
            m = shiftN(m)
        }
        
        if (m & me) != 0 { flips |= captured }
        
        captured = 0
        m = shiftS(move)
        
        while m != 0 && (m & opp) != 0 {
            captured |= m
            m = shiftS(m)
        }
        
        if (m & me) != 0 { flips |= captured }
        
        captured = 0
        m = shiftE(move)
        
        while m != 0 && (m & opp) != 0 {
            captured |= m
            m = shiftE(m)
        }
        
        if (m & me) != 0 { flips |= captured }
        
        captured = 0
        m = shiftW(move)
        
        while m != 0 && (m & opp) != 0 {
            captured |= m
            m = shiftW(m)
        }
        
        if (m & me) != 0 { flips |= captured }
        
        captured = 0
        m = shiftNE(move)
        
        while m != 0 && (m & opp) != 0 {
            captured |= m
            m = shiftNE(m)
        }
        
        if (m & me) != 0 { flips |= captured }
        
        captured = 0
        m = shiftNW(move)
        
        while m != 0 && (m & opp) != 0 {
            captured |= m
            m = shiftNW(m)
        }
        
        if (m & me) != 0 { flips |= captured }
        
        captured = 0
        m = shiftSE(move)
        
        while m != 0 && (m & opp) != 0 {
            captured |= m
            m = shiftSE(m)
        }
        
        if (m & me) != 0 { flips |= captured }
        
        captured = 0
        m = shiftSW(move)
        
        while m != 0 && (m & opp) != 0 {
            captured |= m
            m = shiftSW(m)
        }
        
        if (m & me) != 0 { flips |= captured }
        
        return flips
    }
    
    @inline(__always)
    static func applying(moveIndex: Int, player: CellState, position: Position) -> Position {
        let move = bit(moveIndex)
        let (me, opp) = masks(for: player, in: position)
        let flips = flippedDiscs(move: move, me: me, opp: opp)
        
        if player == .black {
            return Position(
                black: position.black | move | flips,
                white: position.white & ~flips
            )
        } else {
            return Position(
                black: position.black & ~flips,
                white: position.white | move | flips
            )
        }
    }
    
    @inline(__always)
    static func isValidMove(index: Int, player: CellState, position: Position) -> Bool {
        (legalMoves(player: player, position: position) & bit(index)) != 0
    }
    
    static func moveIndices(from moves: UInt64) -> [Int] {
        guard moves != 0 else { return [] }
        
        var result: [Int] = []
        result.reserveCapacity(moves.nonzeroBitCount)
        
        var remaining = moves
        while remaining != 0 {
            let lsb = remaining & (~remaining &+ 1)
            result.append(lsb.trailingZeroBitCount)
            remaining ^= lsb
        }
        
        return result
    }
    
    @inline(__always)
    static func terminalScore(position: Position, aiPlayer: CellState) -> Int {
        let black = position.black.nonzeroBitCount
        let white = position.white.nonzeroBitCount
        let diff = black - white
        
        if diff == 0 { return 0 }
        
        if aiPlayer == .black {
            return diff > 0 ? 1_000_000 + diff : -1_000_000 + diff
        }
        
        return diff < 0 ? 1_000_000 - diff : -1_000_000 - diff
    }
    
    static func evaluate(position: Position, for aiPlayer: CellState) -> Int {
        let (me, opp) = masks(for: aiPlayer, in: position)
        
        var score = 0
        var m = me
        
        while m != 0 {
            let lsb = m & (~m &+ 1)
            score += positionWeights[lsb.trailingZeroBitCount]
            m ^= lsb
        }
        
        var o = opp
        
        while o != 0 {
            let lsb = o & (~o &+ 1)
            score -= positionWeights[lsb.trailingZeroBitCount]
            o ^= lsb
        }
        
        let mobility = legalMoves(player: aiPlayer, position: position).nonzeroBitCount
        - legalMoves(player: aiPlayer.toggle(), position: position).nonzeroBitCount
        score += mobility * 4
        
        let pieceDiff = me.nonzeroBitCount - opp.nonzeroBitCount
        score += pieceDiff
        
        let cornerDiff = (me & corners).nonzeroBitCount - (opp & corners).nonzeroBitCount
        score += cornerDiff * 25
        
        return score
    }
    
    struct TTKey: Hashable {
        var black: UInt64
        var white: UInt64
        var playerIsBlack: Bool
    }
    
    enum TTFlag {
        case exact, lower, upper
    }
    
    struct TTEntry {
        var depth: Int
        var score: Int
        var flag: TTFlag
        var bestMove: Int
    }
    
    static func search(position: Position, player: CellState, depth: Int, aiPlayer: CellState, alpha: Int, beta: Int, tt: inout [TTKey: TTEntry]) -> Int {
        if depth <= 0 {
            return evaluate(position: position, for: aiPlayer)
        }
        
        var a = alpha
        var b = beta
        
        let key = TTKey(black: position.black, white: position.white, playerIsBlack: player == .black)
        let cached = tt[key]
        
        if let cached, cached.depth >= depth {
            switch cached.flag {
            case .exact:
                return cached.score
                
            case .lower:
                a = max(a, cached.score)
                
            case .upper:
                b = min(b, cached.score)
            }
            
            if a >= b {
                return cached.score
            }
        }
        
        let moves = legalMoves(player: player, position: position)
        
        if moves == 0 {
            let oppMoves = legalMoves(player: player.toggle(), position: position)
            
            if oppMoves == 0 {
                return terminalScore(position: position, aiPlayer: aiPlayer)
            }
            
            return search(position: position, player: player.toggle(), depth: depth - 1, aiPlayer: aiPlayer, alpha: a, beta: b, tt: &tt)
        }
        
        let a0 = a
        let b0 = b
        
        var bestMove = -1
        var bestScore = player == aiPlayer ? Int.min : Int.max
        
        if let cached, (moves & bit(cached.bestMove)) != 0 {
            let idx = cached.bestMove
            let next = applying(moveIndex: idx, player: player, position: position)
            let score = search(position: next, player: player.toggle(), depth: depth - 1, aiPlayer: aiPlayer, alpha: a, beta: b, tt: &tt)
            
            bestMove = idx
            bestScore = score
            
            if player == aiPlayer {
                a = max(a, bestScore)
            } else {
                b = min(b, bestScore)
            }
        }
        
        var remaining = moves
        
        if bestMove != -1 {
            remaining &= ~bit(bestMove)
        }
        
        for idx in moveOrder {
            let moveBit = bit(idx)
            guard (remaining & moveBit) != 0 else { continue }
            
            remaining &= ~moveBit
            
            let next = applying(moveIndex: idx, player: player, position: position)
            let score = search(position: next, player: player.toggle(), depth: depth - 1, aiPlayer: aiPlayer, alpha: a, beta: b, tt: &tt)
            
            if player == aiPlayer {
                if score > bestScore {
                    bestScore = score
                    bestMove = idx
                }
                
                a = max(a, bestScore)
                if a >= b { break }
            } else {
                if score < bestScore {
                    bestScore = score
                    bestMove = idx
                }
                
                b = min(b, bestScore)
                if a >= b { break }
            }
            
            if remaining == 0 { break }
        }
        
        let flag: TTFlag
        
        if bestScore <= a0 {
            flag = .upper
        } else if bestScore >= b0 {
            flag = .lower
        } else {
            flag = .exact
        }
        
        tt[key] = TTEntry(depth: depth, score: bestScore, flag: flag, bestMove: bestMove)
        
        return bestScore
    }
    
    static func bestMoveSerial(for player: CellState, depth: Int, position: Position, moves: UInt64) -> Int? {
        var bestScore = Int.min
        var bestMove: Int?
        
        var tt: [TTKey: TTEntry] = [:]
        tt.reserveCapacity(1 << 15)
        
        var a = Int.min / 2
        let b = Int.max / 2
        
        var remaining = moves
        
        for idx in moveOrder {
            let mb = bit(idx)
            guard (remaining & mb) != 0 else { continue }
            remaining &= ~mb
            
            let next = applying(moveIndex: idx, player: player, position: position)
            
            let score: Int
            
            if depth <= 1 {
                score = evaluate(position: next, for: player)
            } else {
                score = search(position: next, player: player.toggle(), depth: depth - 1, aiPlayer: player, alpha: a, beta: b, tt: &tt)
            }
            
            if score > bestScore {
                bestScore = score
                bestMove = idx
            }
            
            a = max(a, bestScore)
            
            if remaining == 0 { break }
        }
        
        return bestMove
    }
    
    static func bestMoveParallel(for player: CellState, depth: Int, on board: [CellState]) async -> Int? {
        let position = position(from: board)
        let moves = legalMoves(player: player, position: position)
        guard moves != 0 else { return nil }
        
        let moveCount = moves.nonzeroBitCount
        if moveCount < 4 || depth <= 2 {
            return bestMoveSerial(for: player, depth: depth, position: position, moves: moves)
        }
        
        let alpha = Int.min / 2
        let beta = Int.max / 2
        
        return await withTaskGroup(of: (Int, Int).self) { group in
            var remaining = moves
            for idx in moveOrder {
                let mb = bit(idx)
                guard (remaining & mb) != 0 else { continue }
                remaining &= ~mb
                
                group.addTask {
                    var tt: [TTKey: TTEntry] = [:]
                    tt.reserveCapacity(1 << 14)
                    
                    let next = applying(moveIndex: idx, player: player, position: position)
                    let score = search(position: next, player: player.toggle(), depth: depth - 1, aiPlayer: player, alpha: alpha, beta: beta, tt: &tt)
                    return (score, idx)
                }
                
                if remaining == 0 { break }
            }
            
            var bestScore = Int.min
            var bestMove: Int?
            
            for await (score, move) in group {
                if score > bestScore {
                    bestScore = score
                    bestMove = move
                }
            }
            
            return bestMove
        }
    }
}
