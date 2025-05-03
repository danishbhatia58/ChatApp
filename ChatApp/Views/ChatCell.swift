//
//  ChatCell.swift
//  ChatApp
//
//  Created by Danish on 03/05/25.
//

import UIKit

class ChatCell: UITableViewCell {
    static let identifier = "ChatCell"

    var messageLabel: UILabel!

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            messageLabel = UILabel()
            messageLabel.numberOfLines = 0
            messageLabel.frame = CGRect(x: 10, y: 10, width: contentView.frame.width - 20, height: contentView.frame.height - 20)
            contentView.addSubview(messageLabel)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
}
