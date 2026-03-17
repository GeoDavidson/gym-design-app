import Foundation
import Combine
import SwiftUI

// MARK: - Quick Action

struct QuickAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

// MARK: - Home View Model

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: Published Properties

    @Published var recentDesigns: [RoomDesign] = []
    @Published var isLoading: Bool = false
    @Published var userName: String = "Designer"

    // MARK: Quick Actions

    let quickActions: [QuickAction] = [
        QuickAction(
            icon: "camera.fill",
            title: "AR Scan",
            subtitle: "Scan your room",
            color: .blue
        ),
        QuickAction(
            icon: "cube.fill",
            title: "Virtual Design",
            subtitle: "Build from scratch",
            color: .purple
        ),
        QuickAction(
            icon: "square.grid.2x2.fill",
            title: "Catalog",
            subtitle: "Browse equipment",
            color: .green
        ),
        QuickAction(
            icon: "brain.head.profile",
            title: "AI Advisor",
            subtitle: "Get recommendations",
            color: .orange
        )
    ]

    // MARK: Computed Properties

    var totalDesigns: Int {
        recentDesigns.count
    }

    var totalEquipmentPlaced: Int {
        recentDesigns.reduce(0) { $0 + $1.equipmentCount }
    }

    // MARK: Data Loading

    func fetchRecentDesigns() async {
        isLoading = true
        defer { isLoading = false }

        // Simulate network delay
        try? await Task.sleep(for: .milliseconds(600))

        recentDesigns = Self.mockDesigns
    }

    // MARK: Mock Data

    private static let mockDesigns: [RoomDesign] = [
        RoomDesign(
            userID: "mock-user-1",
            name: "Home Gym",
            room: Room(
                width: 5.0,
                length: 6.0,
                height: 2.8
            ),
            placements: [
                EquipmentPlacement(equipmentID: "eq-1", positionX: 1, positionY: 0, positionZ: 1),
                EquipmentPlacement(equipmentID: "eq-2", positionX: 2, positionY: 0, positionZ: 3),
                EquipmentPlacement(equipmentID: "eq-3", positionX: 3, positionY: 0, positionZ: 1)
            ],
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        ),
        RoomDesign(
            userID: "mock-user-1",
            name: "Garage Gym",
            room: Room(
                width: 7.0,
                length: 4.5,
                height: 3.0
            ),
            placements: [
                EquipmentPlacement(equipmentID: "eq-4", positionX: 1, positionY: 0, positionZ: 2),
                EquipmentPlacement(equipmentID: "eq-5", positionX: 3, positionY: 0, positionZ: 2)
            ],
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        ),
        RoomDesign(
            userID: "mock-user-1",
            name: "Basement Setup",
            room: Room(
                width: 8.0,
                length: 10.0,
                height: 2.5
            ),
            placements: [
                EquipmentPlacement(equipmentID: "eq-1", positionX: 2, positionY: 0, positionZ: 4),
                EquipmentPlacement(equipmentID: "eq-2", positionX: 4, positionY: 0, positionZ: 4),
                EquipmentPlacement(equipmentID: "eq-3", positionX: 6, positionY: 0, positionZ: 4),
                EquipmentPlacement(equipmentID: "eq-6", positionX: 2, positionY: 0, positionZ: 8),
                EquipmentPlacement(equipmentID: "eq-7", positionX: 5, positionY: 0, positionZ: 8)
            ],
            createdAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        )
    ]
}
