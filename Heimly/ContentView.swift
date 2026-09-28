import SwiftUI
import Playgrounds

struct ContentView: View {
    var body: some View {
        ServerConnectView { serverURL in
            print("Connect to \(serverURL)")
        }
    }
}

#Preview {
    ContentView()
}

#Playground {
    _ = 1 + 2
}
