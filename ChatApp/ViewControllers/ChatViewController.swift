//
//  ChatViewController.swift
//  ChatApp
//
//  Created by Danish on 03/05/25.
//



import UIKit
import Network


class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var tableView = UITableView()
    private var messages: [ChatMessage] = []
    private var failedMessages: [ChatMessage] = []
    
    private let webSocketManager = WebSocketManager()
    private let networkMonitor = NetworkMonitor.shared
    
    private var messageInputField: UITextField!
    private var sendButton: UIButton!
    
    var currentUserId: String = ""
    var chatPreviews: [String: ChatPreview] = [:]

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if var preview = chatPreviews[currentUserId] {
            preview.unreadCount = 0
            chatPreviews[currentUserId] = preview
            NotificationCenter.default.post(name: .chatPreviewUpdated, object: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Chat"
        
        setupTableView()
        setupInputArea()
        
        // Observe the custom notification for received messages
        NotificationCenter.default.addObserver(self, selector: #selector(handleReceivedMessage(_:)), name: .didReceiveMessage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // Start listening for WebSocket messages
        webSocketManager.startListening()
        
        // Monitor network status for retrying failed messages
        networkMonitor.onStatusChange = { [weak self] isConnected in
            if !isConnected {
                DispatchQueue.main.async {
                    self?.showAlert(title: "No Internet", message: "You're offline. Messages will be sent when connection is restored.")
                }
            }
            else{
                
                self?.webSocketManager.reconnect()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    
                    self?.retryFailedMessages()
                }
            }
        }
    }
    
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - 60)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MessageCell")
        view.addSubview(tableView)
    }
    
    func setupInputArea() {
        messageInputField = UITextField()
        messageInputField.frame = CGRect(x: 10, y: view.bounds.height - 60, width: view.bounds.width - 80, height: 40)
        messageInputField.placeholder = "Enter message"
        messageInputField.borderStyle = .roundedRect
        messageInputField.delegate = self
        
        view.addSubview(messageInputField)
        
        sendButton = UIButton(type: .system)
        sendButton.frame = CGRect(x: view.bounds.width - 60, y: view.bounds.height - 60, width: 50, height: 40)
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        view.addSubview(sendButton)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc func sendMessage() {
        guard let messageText = messageInputField.text, !messageText.isEmpty else { return }

        // Create message with `queued` status
        let chatMessage = ChatMessage(text: messageText, type: .queued, status: .sent)
        messages.append(chatMessage)
        tableView.reloadData()

        messageInputField.text = ""

        // Try sending via WebSocket
        webSocketManager.sendMessage(messageText) { success in
            DispatchQueue.main.async {
                if let index = self.messages.lastIndex(where: { $0.text == messageText && $0.status == .sent }) {
                    if success {
                        self.messages[index].type = .sent
                        self.failedMessages.removeAll { $0.text == messageText }
                    } else {
                        self.messages[index].type = .failed
                        self.failedMessages.append(self.messages[index])
                    }
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                }
            }
        }
    }

    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            UIView.animate(withDuration: 0.3) {
                self.messageInputField.frame.origin.y = self.view.bounds.height - keyboardHeight - 60
                self.sendButton.frame.origin.y = self.view.bounds.height - keyboardHeight - 60
                self.tableView.frame.size.height = self.view.bounds.height - keyboardHeight - 60
            }
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.3) {
            self.messageInputField.frame.origin.y = self.view.bounds.height - 60
            self.sendButton.frame.origin.y = self.view.bounds.height - 60
            self.tableView.frame.size.height = self.view.bounds.height - 60
        }
    }

    @objc func handleReceivedMessage(_ notification: Notification) {
        guard let message = notification.object as? String else { return }

        print("Received message: \(message)")

        // Avoid re-adding your own message
        if messages.contains(where: { $0.text == message && $0.type == .sent }) {
            return
        }

        // Append only if it's new or from someone else
        let chatMessage = ChatMessage(text: message, type: .sent, status: .received)
        messages.append(chatMessage)

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }


    
    func retryFailedMessages() {
        for failedMessage in failedMessages {
            guard failedMessage.type == .failed else { continue }

            webSocketManager.sendMessage(failedMessage.text) { success in
                DispatchQueue.main.async {
                    if success {
                        if let index = self.messages.firstIndex(where: { $0.text == failedMessage.text && $0.type == .failed }) {
                            self.messages[index].type = .sent
                            self.failedMessages.removeAll { $0.text == failedMessage.text }
                            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                        }
                    }
                }
            }
        }
    }

    
    func updatePreview(with message: String, from userId: String, isCurrentChat: Bool) {
        if var preview = chatPreviews[userId] {
            preview.lastMessage = message
            preview.unreadCount = isCurrentChat ? 0 : preview.unreadCount + 1
            chatPreviews[userId] = preview
        } else {
            chatPreviews[userId] = ChatPreview(userId: userId, lastMessage: message, unreadCount: isCurrentChat ? 0 : 1)
        }

        NotificationCenter.default.post(name: .chatPreviewUpdated, object: nil)
    }


    //MARK: TABLE
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if messages.isEmpty {
            let noDataLabel = UILabel(frame: tableView.bounds)
            noDataLabel.text = "No chats yet"
            noDataLabel.textAlignment = .center
            tableView.backgroundView = noDataLabel
        }
        else {
            
            tableView.backgroundView = nil
        }
        
        return messages.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        let message = messages[indexPath.row]

        var displayText = ""
        if message.status == .sent {
            switch message.type {
            case .queued:
                displayText = "⏳ Sending: \(message.text)"
            case .failed:
                displayText = "❌ Failed: \(message.text)"
            case .sent:
                displayText = "You: \(message.text)"
            }
            cell.textLabel?.textAlignment = .right
        } else {
            displayText = "Friend: \(message.text)"
            cell.textLabel?.textAlignment = .left
        }

        cell.textLabel?.text = displayText
        return cell
    }

    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .didReceiveMessage, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        textField.resignFirstResponder()

        return true
    }
}

