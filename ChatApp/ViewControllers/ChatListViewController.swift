//
//  ChatListViewController.swift
//  ChatApp
//
//  Created by Danish on 03/05/25.
//

import UIKit


extension Notification.Name {
    static let chatPreviewUpdated = Notification.Name("chatPreviewUpdated")
}

class ChatListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private var tableView = UITableView()
    
    // Dictionary of chat previews keyed by userId
    var chatPreviews: [String: ChatPreview] = [
        "P1": ChatPreview(userId: "1", lastMessage: "", unreadCount: 2),
    ] 



    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chats"
        view.backgroundColor = .white

        setupTableView()

        NotificationCenter.default.addObserver(self, selector: #selector(reloadPreviews), name: .chatPreviewUpdated, object: nil)
    }

    func setupTableView() {
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChatCell")
        view.addSubview(tableView)
    }

    @objc func reloadPreviews() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // MARK: UITableView DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatPreviews.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
        let preview = Array(chatPreviews.values)[indexPath.row]

        var labelText = "User \(preview.userId): \(preview.lastMessage)"
        if preview.unreadCount > 0 {
            labelText += " (\(preview.unreadCount) new)"
        }

        cell.textLabel?.text = labelText
        cell.textLabel?.font = preview.unreadCount > 0 ? .boldSystemFont(ofSize: 16) : .systemFont(ofSize: 16)

        return cell
    }

    // MARK: Navigation

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let preview = Array(chatPreviews.values)[indexPath.row]
        let chatVC = ChatViewController()
        chatVC.currentUserId = preview.userId
        chatVC.chatPreviews = chatPreviews // pass reference
        navigationController?.pushViewController(chatVC, animated: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

