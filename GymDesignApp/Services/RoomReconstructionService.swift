import Foundation
import ARKit
import simd

// MARK: - Room Reconstruction Service

/// Estimates room geometry from AR plane anchors detected during a scanning session.
final class RoomReconstructionService {

    // MARK: - Bounding Box

    private struct BoundingBox {
        var minX: Float = .greatestFiniteMagnitude
        var maxX: Float = -.greatestFiniteMagnitude
        var minY: Float = .greatestFiniteMagnitude
        var maxY: Float = -.greatestFiniteMagnitude
        var minZ: Float = .greatestFiniteMagnitude
        var maxZ: Float = -.greatestFiniteMagnitude

        var extentX: Float { max(maxX - minX, 0) }
        var extentY: Float { max(maxY - minY, 0) }
        var extentZ: Float { max(maxZ - minZ, 0) }

        var center: SIMD3<Float> {
            SIMD3<Float>(
                (minX + maxX) / 2,
                (minY + maxY) / 2,
                (minZ + maxZ) / 2
            )
        }

        var isValid: Bool {
            extentX > 0.1 && extentZ > 0.1
        }

        mutating func expand(with point: SIMD3<Float>) {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
            minZ = min(minZ, point.z)
            maxZ = max(maxZ, point.z)
        }
    }

    // MARK: - Public API

    /// Estimates a `Room` from detected AR plane anchors.
    ///
    /// Uses horizontal planes for the floor extents and vertical planes for wall positions.
    /// Falls back to default room height if no vertical planes provide enough information.
    ///
    /// - Parameter planes: Array of detected `ARPlaneAnchor` instances.
    /// - Returns: An estimated `Room`, or `nil` if insufficient data.
    func estimateRoom(from planes: [ARPlaneAnchor]) -> Room? {
        guard !planes.isEmpty else { return nil }

        let horizontals = planes.filter { $0.alignment == .horizontal }
        let verticals = planes.filter { $0.alignment == .vertical }

        // We need at least one horizontal plane to estimate floor area.
        guard !horizontals.isEmpty else { return nil }

        var bbox = BoundingBox()

        // Expand bounding box with horizontal planes
        for plane in horizontals {
            let corners = planeCorners(plane)
            for corner in corners {
                bbox.expand(with: corner)
            }
        }

        // Expand bounding box with vertical planes
        for plane in verticals {
            let corners = planeCorners(plane)
            for corner in corners {
                bbox.expand(with: corner)
            }
        }

        guard bbox.isValid else { return nil }

        // Estimate room dimensions
        let width = clampDimension(bbox.extentX)
        let length = clampDimension(bbox.extentZ)

        // Height: use vertical extent if we have meaningful vertical planes,
        // otherwise fall back to default ceiling height.
        let height: Float
        if !verticals.isEmpty && bbox.extentY > 0.5 {
            height = clampDimension(bbox.extentY)
        } else {
            height = Float(AppConstants.DefaultRoom.height)
        }

        return Room(
            width: width,
            length: length,
            height: height,
            origin: bbox.center
        )
    }

    /// Returns a coarse scan completeness score (0...1) based on detected plane coverage.
    ///
    /// Heuristic:
    /// - 0.3 for at least one horizontal plane detected
    /// - Up to 0.7 for wall coverage (4 unique wall directions)
    func estimateScanCompleteness(planes: [ARPlaneAnchor]) -> Float {
        var score: Float = 0

        let horizontals = planes.filter { $0.alignment == .horizontal }
        let verticals = planes.filter { $0.alignment == .vertical }

        // Floor detection bonus
        if !horizontals.isEmpty {
            score += 0.3
        }

        // Wall detection — cluster vertical planes by facing direction
        let wallDirections = classifyWallDirections(verticals)
        let wallScore = min(Float(wallDirections) * 0.175, 0.7)
        score += wallScore

        return min(score, 1.0)
    }

    // MARK: - Private Helpers

    /// Returns the four world-space corners of a plane anchor's extent rectangle.
    private func planeCorners(_ plane: ARPlaneAnchor) -> [SIMD3<Float>] {
        let extent = plane.planeExtent
        let halfWidth = extent.width / 2
        let halfHeight = extent.height / 2

        let localCorners: [SIMD3<Float>] = [
            SIMD3<Float>(-halfWidth, 0, -halfHeight),
            SIMD3<Float>( halfWidth, 0, -halfHeight),
            SIMD3<Float>( halfWidth, 0,  halfHeight),
            SIMD3<Float>(-halfWidth, 0,  halfHeight)
        ]

        let transform = plane.transform
        return localCorners.map { local in
            let worldPos = transform * SIMD4<Float>(local.x, local.y, local.z, 1.0)
            return SIMD3<Float>(worldPos.x, worldPos.y, worldPos.z)
        }
    }

    /// Classifies vertical planes into approximate wall facing directions.
    /// Returns the number of distinct wall directions found (max 4).
    private func classifyWallDirections(_ verticals: [ARPlaneAnchor]) -> Int {
        var directions: Set<WallDirection> = []

        for plane in verticals {
            let normal = SIMD3<Float>(
                plane.transform.columns.2.x,
                plane.transform.columns.2.y,
                plane.transform.columns.2.z
            )

            let absX = abs(normal.x)
            let absZ = abs(normal.z)

            if absX > absZ {
                directions.insert(normal.x > 0 ? .positiveX : .negativeX)
            } else {
                directions.insert(normal.z > 0 ? .positiveZ : .negativeZ)
            }
        }

        return directions.count
    }

    private enum WallDirection: Hashable {
        case positiveX, negativeX, positiveZ, negativeZ
    }

    /// Clamps a dimension to the app-supported range.
    private func clampDimension(_ value: Float) -> Float {
        let minDim = Float(AppConstants.DefaultRoom.minDimension)
        let maxDim = Float(AppConstants.DefaultRoom.maxDimension)
        return min(max(value, minDim), maxDim)
    }
}
