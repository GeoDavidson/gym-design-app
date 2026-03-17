import Foundation
import FirebaseFirestore

// MARK: - Firestore Error

enum FirestoreError: LocalizedError {
    case documentNotFound(collection: String, id: String)
    case decodingFailed(underlying: Error)
    case encodingFailed(underlying: Error)
    case queryFailed(underlying: Error)
    case writeFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case listenerFailed(underlying: Error)
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .documentNotFound(let collection, let id):
            return "Document '\(id)' not found in '\(collection)'."
        case .decodingFailed(let error):
            return "Failed to decode document: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to encode document: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "Query failed: \(error.localizedDescription)"
        case .writeFailed(let error):
            return "Write failed: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Delete failed: \(error.localizedDescription)"
        case .listenerFailed(let error):
            return "Listener failed: \(error.localizedDescription)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Query Filter

struct QueryFilter {
    let field: String
    let op: FilterOperator
    let value: Any

    enum FilterOperator {
        case isEqualTo
        case isLessThan
        case isLessThanOrEqualTo
        case isGreaterThan
        case isGreaterThanOrEqualTo
        case arrayContains
        case isIn
    }
}

// MARK: - Firestore Service Protocol

protocol FirestoreServiceProtocol {
    func fetch<T: Codable>(collection: String, id: String) async throws -> T
    func fetchAll<T: Codable>(collection: String, filters: [QueryFilter], limit: Int?) async throws -> [T]
    func save<T: Codable>(_ item: T, collection: String, id: String) async throws
    func delete(collection: String, id: String) async throws
    func listen<T: Codable>(collection: String, id: String) -> AsyncStream<T?>
}

// MARK: - Firestore Service

final class FirestoreService: FirestoreServiceProtocol {

    // MARK: Shared Instance

    static let shared = FirestoreService()

    // MARK: Private Properties

    private let db: Firestore
    private let encoder: Firestore.Encoder
    private let decoder: Firestore.Decoder

    // MARK: Initialization

    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore

        self.encoder = Firestore.Encoder()
        encoder.dateEncodingStrategy = .timestamp

        self.decoder = Firestore.Decoder()
        decoder.dateDecodingStrategy = .timestamp
    }

    // MARK: Fetch Single Document

    func fetch<T: Codable>(collection: String, id: String) async throws -> T {
        do {
            let snapshot = try await db.collection(collection).document(id).getDocument()

            guard snapshot.exists else {
                throw FirestoreError.documentNotFound(collection: collection, id: id)
            }

            do {
                let item = try snapshot.data(as: T.self, decoder: decoder)
                return item
            } catch {
                throw FirestoreError.decodingFailed(underlying: error)
            }
        } catch let error as FirestoreError {
            throw error
        } catch {
            throw FirestoreError.queryFailed(underlying: error)
        }
    }

    // MARK: Fetch All Documents

    func fetchAll<T: Codable>(
        collection: String,
        filters: [QueryFilter] = [],
        limit: Int? = nil
    ) async throws -> [T] {
        do {
            var query: Query = db.collection(collection)

            for filter in filters {
                query = applyFilter(filter, to: query)
            }

            if let limit {
                query = query.limit(to: limit)
            }

            let snapshot = try await query.getDocuments()

            return snapshot.documents.compactMap { document in
                do {
                    return try document.data(as: T.self, decoder: decoder)
                } catch {
                    print("[FirestoreService] Skipping document \(document.documentID): \(error.localizedDescription)")
                    return nil
                }
            }
        } catch let error as FirestoreError {
            throw error
        } catch {
            throw FirestoreError.queryFailed(underlying: error)
        }
    }

    // MARK: Save Document

    func save<T: Codable>(_ item: T, collection: String, id: String) async throws {
        do {
            try db.collection(collection).document(id).setData(from: item, merge: true, encoder: encoder)
        } catch {
            throw FirestoreError.writeFailed(underlying: error)
        }
    }

    // MARK: Delete Document

    func delete(collection: String, id: String) async throws {
        do {
            try await db.collection(collection).document(id).delete()
        } catch {
            throw FirestoreError.deleteFailed(underlying: error)
        }
    }

    // MARK: Real-Time Listener

    func listen<T: Codable>(collection: String, id: String) -> AsyncStream<T?> {
        AsyncStream { continuation in
            let docRef = db.collection(collection).document(id)

            let listener = docRef.addSnapshotListener { [weak self] snapshot, error in
                guard let self else {
                    continuation.finish()
                    return
                }

                if let error {
                    print("[FirestoreService] Listener error for \(collection)/\(id): \(error.localizedDescription)")
                    continuation.yield(nil)
                    return
                }

                guard let snapshot, snapshot.exists else {
                    continuation.yield(nil)
                    return
                }

                do {
                    let item = try snapshot.data(as: T.self, decoder: self.decoder)
                    continuation.yield(item)
                } catch {
                    print("[FirestoreService] Decode error in listener: \(error.localizedDescription)")
                    continuation.yield(nil)
                }
            }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    // MARK: - Listen to Collection

    func listenAll<T: Codable>(
        collection: String,
        filters: [QueryFilter] = [],
        limit: Int? = nil
    ) -> AsyncStream<[T]> {
        AsyncStream { continuation in
            var query: Query = db.collection(collection)

            for filter in filters {
                query = applyFilter(filter, to: query)
            }

            if let limit {
                query = query.limit(to: limit)
            }

            let listener = query.addSnapshotListener { [weak self] snapshot, error in
                guard self != nil else {
                    continuation.finish()
                    return
                }

                if let error {
                    print("[FirestoreService] Collection listener error: \(error.localizedDescription)")
                    continuation.yield([])
                    return
                }

                guard let snapshot else {
                    continuation.yield([])
                    return
                }

                let items: [T] = snapshot.documents.compactMap { doc in
                    try? doc.data(as: T.self)
                }
                continuation.yield(items)
            }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    // MARK: Private Helpers

    private func applyFilter(_ filter: QueryFilter, to query: Query) -> Query {
        switch filter.op {
        case .isEqualTo:
            return query.whereField(filter.field, isEqualTo: filter.value)
        case .isLessThan:
            return query.whereField(filter.field, isLessThan: filter.value)
        case .isLessThanOrEqualTo:
            return query.whereField(filter.field, isLessThanOrEqualTo: filter.value)
        case .isGreaterThan:
            return query.whereField(filter.field, isGreaterThan: filter.value)
        case .isGreaterThanOrEqualTo:
            return query.whereField(filter.field, isGreaterThanOrEqualTo: filter.value)
        case .arrayContains:
            return query.whereField(filter.field, arrayContains: filter.value)
        case .isIn:
            return query.whereField(filter.field, in: filter.value as! [Any])
        }
    }
}
