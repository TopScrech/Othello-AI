enum CellState {
    case empty, black, white
    
    func toggle() -> CellState {
        switch self {
        case.black: .white
        case.white: .black
        default: .empty
        }
    }
}
