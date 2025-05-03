//
//  NetworkMonitor.swift
//  ChatApp
//
//  Created by Danish on 03/05/25.
//


import Network

class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private(set) var isConnected: Bool = true {
        didSet {
            if oldValue != isConnected {
                DispatchQueue.main.async {
                    self.onStatusChange?(self.isConnected)
                }
            }
        }
    }
    
    var onStatusChange: ((Bool) -> Void)?
    
    private init() {
        monitor = NWPathMonitor()
        
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let status = path.status == .satisfied
            print("Network status changed: \(status ? "Connected" : "Disconnected")")
            self.isConnected = status
        }
        
        monitor.start(queue: queue)
    }
}

