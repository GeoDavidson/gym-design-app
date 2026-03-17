import simd
import Foundation

// MARK: - SIMD3<Float> Codable

extension SIMD3: @retroactive Codable where Scalar == Float {
    enum CodingKeys: String, CodingKey { case x, y, z }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(try c.decode(Float.self, forKey: .x), try c.decode(Float.self, forKey: .y), try c.decode(Float.self, forKey: .z))
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(x, forKey: .x); try c.encode(y, forKey: .y); try c.encode(z, forKey: .z)
    }
}

// MARK: - simd_quatf Codable

extension simd_quatf: @retroactive Codable {
    enum CodingKeys: String, CodingKey { case ix, iy, iz, r }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let v = SIMD3<Float>(try c.decode(Float.self, forKey: .ix), try c.decode(Float.self, forKey: .iy), try c.decode(Float.self, forKey: .iz))
        self.init(ix: v.x, iy: v.y, iz: v.z, r: try c.decode(Float.self, forKey: .r))
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(imag.x, forKey: .ix); try c.encode(imag.y, forKey: .iy); try c.encode(imag.z, forKey: .iz); try c.encode(real, forKey: .r)
    }
}

// MARK: - SIMD3<Float> Distance & Conversion Helpers

extension SIMD3 where Scalar == Float {
    /// Euclidean distance to another point.
    func distance(to other: SIMD3<Float>) -> Float { simd_distance(self, other) }

    /// The zero vector.
    static var zero: SIMD3<Float> { SIMD3<Float>(0, 0, 0) }

    /// Converts meters to feet (1 m = 3.28084 ft).
    func metersToFeet() -> SIMD3<Float> { self * 3.28084 }

    /// Converts feet to meters (1 ft = 0.3048 m).
    func feetToMeters() -> SIMD3<Float> { self * 0.3048 }

    /// Returns a formatted string of the vector components rounded to one decimal.
    var displayString: String {
        String(format: "(%.1f, %.1f, %.1f)", x, y, z)
    }

    /// Linear interpolation between self and another vector.
    func lerp(to target: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        self + (target - self) * t
    }

    /// Magnitude (length) of the vector.
    var magnitude: Float { simd_length(self) }

    /// Normalized (unit) vector; returns zero if magnitude is zero.
    var normalized: SIMD3<Float> {
        let m = magnitude
        return m > 0 ? self / m : .zero
    }
}

// MARK: - simd_quatf Helpers

extension simd_quatf {
    /// Identity quaternion (no rotation).
    static var identity: simd_quatf { simd_quatf(ix: 0, iy: 0, iz: 0, r: 1) }

    /// Y-axis rotation angle in radians.
    var yawAngle: Float {
        let siny = 2.0 * (real * imag.y + imag.x * imag.z)
        let cosy = 1.0 - 2.0 * (imag.y * imag.y + imag.z * imag.z)
        return atan2(siny, cosy)
    }

    /// Creates a quaternion from a Y-axis rotation in degrees.
    static func fromYawDegrees(_ degrees: Float) -> simd_quatf {
        simd_quatf(angle: degrees * .pi / 180.0, axis: SIMD3<Float>(0, 1, 0))
    }
}
