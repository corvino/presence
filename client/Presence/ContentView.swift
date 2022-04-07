import SwiftUI

struct ContentView: View {
    @StateObject var client = PresenceClient()

    var body: some View {
        VStack {
            Text("Hello, world!")
            Button {
                client.ping()
            } label: {
                Text("Ping")
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
