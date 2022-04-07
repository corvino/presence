import Foundation

enum Message: Codable {
    case connected(clientID: Int)
    case ping
    case pong
}

class PresenceClient: ObservableObject {
    enum State {
        case invalid(reason: String)
        case connected(socket: URLSessionWebSocketTask)
    }

    private var state: State

    private let session = URLSession(configuration: .default)
    var ok = true

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

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
        let decoder = JSONDecoder()

        do {
            let message = try decoder.decode(Message.self, from: data)

            switch message {
            case .connected(clientID: let clientID):
                print("connected", clientID)
            case .pong:
                print("pong")
            default:
                break
            }
        } catch {
            print("Error processing message:", error)
        }
    }

    private func send(data: Data) {
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

    private func send<T>(message: T) where T: Codable {
        guard let data = try? JSONEncoder().encode(message) else { return }
        send(data: data)
    }

    func ping() {
        send(message: Message.ping)
    }
}
