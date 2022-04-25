import SwiftUI

struct ContentView: View {
    @StateObject var client = PresenceClient()

    @State var username = ""
    @State var enteredUsername = ""
    @FocusState private var usernameFocused: Bool
    @State var changeUsername = false

    var body: some View {
        VStack {
            HStack {
                switch client.state {
                case .connected:
                    Image(systemName: "circle.inset.filled")
                        .foregroundStyle(.green, .gray)
                        .onTapGesture { client.disconnect() }
                case .connecting:
                    Image(systemName: "circle.inset.filled")
                        .foregroundStyle(.orange, .gray)
                        .onTapGesture { client.disconnect() }
                case .disconnected:
                    Image(systemName: "circle.inset.filled")
                        .foregroundStyle(.red, .gray)
                        .onTapGesture { client.connect() }
                }

                if changeUsername {
                    TextField("Username", text: $enteredUsername)
                        .focused($usernameFocused)
                        .onSubmit {
                            username = enteredUsername
                            changeUsername = false
                        }
                        .onExitCommand {
                            enteredUsername = username
                            changeUsername = false

                        }
                } else {
                    let edit = {
                        changeUsername = true
                        usernameFocused = true
                    }

                    if let name = client.name, 0 < name.count {
                        Text(name).onTapGesture(perform: edit)
                    } else {
                        Text("<New user>").italic().onTapGesture(perform: edit)
                    }
                }
                Spacer()
            }
            .frame(minHeight: 10)

            Button {
                client.ping()
            } label: {
                Text("Ping")
            }
            .focusable()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
