//
//  SocketManager.swift
//  ChatApp
//
//  Created by Danish on 03/05/25.
//

import Foundation

// Notification name extension
extension NSNotification.Name {
    static let didReceiveMessage = NSNotification.Name("didReceiveMessage")
}

class WebSocketManager: NSObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    var isConnected: Bool = false
    private var webSocketURL: URL? // Store the URL for reconnection
    
    override init() {
        super.init()
        self.webSocketURL = URL(string: "wss://demo.piesocket.com/v3/channel_123?api_key=IEzmgvU7AEb5jeLrgABo2YM21fRfkE8UwIvs0MTP&notify_self")!
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = urlSession?.webSocketTask(with: webSocketURL!)
    }

    func startListening() {
        webSocketTask?.resume()
        self.isConnected = true
        listenForMessages()
    }
    
    func disconnect() {
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        
        isConnected = false
    }
    
    func reconnect() {
        
        disconnect()

        guard let url = webSocketURL else { return }
        
        webSocketTask = urlSession?.webSocketTask(with: url)
       
        startListening()
    }
    

    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Failed to receive message: \(error)")
                self?.isConnected = false
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received message: \(text)")
                    NotificationCenter.default.post(name: .didReceiveMessage, object: text)
                default:
                    break
                }
            }
            self?.listenForMessages()
        }
    }

    func sendMessage(_ message: String, completion: @escaping (Bool) -> Void) {
        guard isConnected else {
            print("WebSocket not connected. Queueing message.")
            completion(false) 
            return
        }

        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Failed to send message: \(error)")
                completion(false) // Notify failure
            } else {
                completion(true) // Notify success
            }
        }
    }

   
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
        isConnected = true
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWithError error: Error?) {
        print("WebSocket disconnected")
        isConnected = false
    }
}


