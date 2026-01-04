import SwiftUI

struct AppContainer: View {
    var body: some View {
        NavigationStack {
            OthelloBoard()
        }
    }
}

#Preview {
    AppContainer()
}
