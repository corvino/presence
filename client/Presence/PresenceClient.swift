import Foundation

class PresenceClient: ObservableObject {
    enum State {
        case invalid(reason: String)
        case connected(socket: URLSessionWebSocketTask)
    }

    private var state: State

    private let session = URLSession(configuration: .default)
    var ok = true

    init() {
        let urlString = "ws://localhost:3000/connect"
        guard let url = URL(string: urlString) else { state = .invalid(reason: "invalid URL"); return }

        let socket = session.webSocketTask(with: url)

        state = .connected(socket: socket)
        let process = { [weak self] in
            do {
                while (true) {
                    guard let self = self else { break }
                    self.receive(message: try await socket.receive())
                }
            } catch {
                // Do error/disconncted stuff here.
                print(error)
            }
        }
        Task.detached { await process() }
        socket.resume()
    }

    deinit{
        switch state {
        case .invalid:
            print("not connected")
        case let .connected(socket: socket):
            socket.cancel(with: .goingAway, reason: nil)
        }
    }

    private func receive(message:  URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            receive(data: data)
        case .string(let str):
            guard let data = str.data(using: .utf8) else { return }
            receive(data: data)
        @unknown default:
            break
        }
    }

    private func receive(data: Data) {
        print(String(decoding: data, as: UTF8.self))
    }

    private func sendData(_ data: Data) {
        switch state {
        case .invalid:
            print("not connected")
            case let .connected(socket: socket):
            socket.send(.data(data)) { (err) in
                if nil != err {
                    print(err.debugDescription)
                }
            }
        }
    }

    func ping() {
        guard let data = "ping".data(using: .utf8) else { return }
        sendData(data)
    }
}
