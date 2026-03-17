import Foundation
import Network
import Combine

// MARK: - Connection Type

enum ConnectionType: String, CaseIterable {
    case wifi
    case cellular
    case wired
    case unknown
}

// MARK: - Network Monitor

/// Observes network reachability changes and publishes connectivity state.
final class NetworkMonitor: ObservableObject {

    // MARK: - Singleton

    static let shared = NetworkMonitor()

    // MARK: - Published State

    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .unknown

    // MARK: - Private

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.gymdesign.networkmonitor", qos: .utility)

    // MARK: - Initialization

    private init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Monitoring

    /// Begins monitoring network path changes.
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = (path.status == .satisfied)
                self?.connectionType = self?.resolveConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }

    /// Stops monitoring network path changes.
    func stopMonitoring() {
        monitor.cancel()
    }

    // MARK: - Helpers

    private func resolveConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        } else {
            return .unknown
        }
    }
}
