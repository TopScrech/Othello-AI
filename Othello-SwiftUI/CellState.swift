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
