import Foundation

enum Message: Codable {
    case connected(clientID: Int)
    case createUser
    case userCreated(name: String)
    case login(name: String)
    case loggedIn(name: String)
    case changeName(name: String)
    case nameChanged(name: String)
    case ping
    case pong
}

enum ClientError: Error {
    case alreadyConnected
    case disconnected
}

class WebSocketConnectCallback: NSObject, URLSessionTaskDelegate, URLSessionWebSocketDelegate {
    private weak var delegate: PresenceClient?

    init(client: PresenceClient) {
        self.delegate = client
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("didCloseWith")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("didOpenWithProtocol")
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.state = .connected(socket: webSocketTask)
            self?.delegate?.onConnect()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("completed with error: \(error as Error?)")
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.state = .disconnected
        }
    }
}

class PresenceClient: ObservableObject {
    enum State {
        case connecting(socket: URLSessionWebSocketTask)
        case connected(socket: URLSessionWebSocketTask)
        case disconnected
    }

    @Published var state = State.disconnected
    @Published var name: String? = nil

    private let session = URLSession(configuration: .default)
    var ok = true

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private var socket: URLSessionWebSocketTask? {
        get {
            switch self.state {
            case .connected(socket: let socket), .connecting(socket: let socket):
                return socket
            default:
                return nil
            }
        }
    }

    deinit {
        switch state {
        case let .connected(socket: socket), let .connecting(socket: socket):
            print("close socket")
            socket.cancel(with: .goingAway, reason: nil)
        case .disconnected:
            break
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
        print("received")
        let decoder = JSONDecoder()

        do {
            let message = try decoder.decode(Message.self, from: data)

            switch message {
            case .connected(clientID: let clientID):
                print("connected", clientID)
            case .userCreated(let name):
                print("created")
                DispatchQueue.main.async { self.name = name }
            case .loggedIn(let name):
                self.name = name
            case .nameChanged(let name):
                self.name = name
            case .pong:
                print("pong")
            default:
                print("unknown message type")
                break
            }
        } catch {
            print("Error processing message:", error)
        }
    }

    private func send(data: Data) {
        switch state {
        case .disconnected, .connecting:
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

    func onConnect() {
        if let name = name {
            send(message: Message.login(name: name))
        } else {
            send(message: Message.createUser)
        }
    }

    func connect(name: String? = nil) {
        switch state {
        case .connected, .connecting:
            print("client already connected")
        case .disconnected:
            let urlString = "ws://localhost:3000/connect"
            guard let url = URL(string: urlString) else { state = .disconnected; return }

            let socket = session.webSocketTask(with: url)
            socket.delegate = WebSocketConnectCallback(client: self)

            state = .connecting(socket: socket)
            let process = { [weak self] in
                do {
                    while (true) {
                        // guard case .connected(let socket) = self?.state else { break }
                        guard let socket = self?.socket else { return }

                        // It is important to not create a retain cycle prior to the await.
                        let message = try await socket.receive()
                        self?.receive(message: message)

                    }
                } catch {
                    print(error)
                    guard let self = self else { return }
                    DispatchQueue.main.async { self.state = .disconnected }
                }
            }
            Task.detached { await process() }
            socket.resume()
        }
    }

    func disconnect() {
        switch state {
        case .connected(let socket), .connecting(let socket):
            socket.cancel(with: .goingAway, reason: nil)
            state = .disconnected
        case .disconnected:
            print("client already disconncted")
        }
    }

    func ping() {
        send(message: Message.ping)
    }

    func login(name: String) {
        send(message: Message.login(name: name))
    }
}
