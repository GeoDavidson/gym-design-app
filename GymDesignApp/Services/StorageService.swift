import Foundation
import FirebaseStorage

// MARK: - Storage Error

enum StorageError: LocalizedError {
    case uploadFailed(underlying: Error)
    case downloadURLFailed(underlying: Error)
    case downloadFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case invalidData
    case fileTooLarge(maxMB: Int)

    var errorDescription: String? {
        switch self {
        case .uploadFailed(let error):
            return "Upload failed: \(error.localizedDescription)"
        case .downloadURLFailed(let error):
            return "Failed to retrieve download URL: \(error.localizedDescription)"
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Delete failed: \(error.localizedDescription)"
        case .invalidData:
            return "The provided data is invalid or empty."
        case .fileTooLarge(let maxMB):
            return "File exceeds the maximum allowed size of \(maxMB) MB."
        }
    }
}

// MARK: - Upload Progress

struct UploadProgress: Sendable {
    let bytesTransferred: Int64
    let totalBytes: Int64

    var fractionCompleted: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesTransferred) / Double(totalBytes)
    }

    var isComplete: Bool {
        totalBytes > 0 && bytesTransferred >= totalBytes
    }
}

// MARK: - Storage Service Protocol

protocol StorageServiceProtocol {
    func uploadImage(data: Data, path: String) async throws -> URL
    func uploadUSDZ(data: Data, path: String) async throws -> URL
    func uploadImageWithProgress(data: Data, path: String) -> (url: Task<URL, Error>, progress: AsyncStream<UploadProgress>)
    func downloadToLocal(remotePath: String, localURL: URL) async throws
    func deleteFile(path: String) async throws
}

// MARK: - Storage Service

final class StorageService: StorageServiceProtocol {

    // MARK: Shared Instance

    static let shared = StorageService()

    // MARK: Private Properties

    private let storage: Storage
    private let maxImageSizeMB: Int = 10
    private let maxModelSizeMB: Int = 100

    // MARK: Initialization

    init(storage: Storage = Storage.storage()) {
        self.storage = storage
    }

    // MARK: Upload Image

    func uploadImage(data: Data, path: String) async throws -> URL {
        guard !data.isEmpty else { throw StorageError.invalidData }

        let sizeMB = data.count / (1024 * 1024)
        guard sizeMB <= maxImageSizeMB else {
            throw StorageError.fileTooLarge(maxMB: maxImageSizeMB)
        }

        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        do {
            _ = try await ref.putDataAsync(data, metadata: metadata)
        } catch {
            throw StorageError.uploadFailed(underlying: error)
        }

        do {
            return try await ref.downloadURL()
        } catch {
            throw StorageError.downloadURLFailed(underlying: error)
        }
    }

    // MARK: Upload USDZ Model

    func uploadUSDZ(data: Data, path: String) async throws -> URL {
        guard !data.isEmpty else { throw StorageError.invalidData }

        let sizeMB = data.count / (1024 * 1024)
        guard sizeMB <= maxModelSizeMB else {
            throw StorageError.fileTooLarge(maxMB: maxModelSizeMB)
        }

        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "model/vnd.usdz+zip"

        do {
            _ = try await ref.putDataAsync(data, metadata: metadata)
        } catch {
            throw StorageError.uploadFailed(underlying: error)
        }

        do {
            return try await ref.downloadURL()
        } catch {
            throw StorageError.downloadURLFailed(underlying: error)
        }
    }

    // MARK: Upload with Progress

    func uploadImageWithProgress(
        data: Data,
        path: String
    ) -> (url: Task<URL, Error>, progress: AsyncStream<UploadProgress>) {
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        var progressContinuation: AsyncStream<UploadProgress>.Continuation?

        let progressStream = AsyncStream<UploadProgress> { continuation in
            progressContinuation = continuation
        }

        let urlTask = Task<URL, Error> {
            guard !data.isEmpty else { throw StorageError.invalidData }

            let uploadTask = ref.putData(data, metadata: metadata)

            // Observe progress on the upload task.
            let observation = uploadTask.observe(.progress) { snapshot in
                guard let progress = snapshot.progress else { return }
                progressContinuation?.yield(
                    UploadProgress(
                        bytesTransferred: progress.completedUnitCount,
                        totalBytes: progress.totalUnitCount
                    )
                )
            }

            // Await the upload completion via a continuation.
            return try await withCheckedThrowingContinuation { continuation in
                uploadTask.observe(.success) { _ in
                    uploadTask.removeObserver(withHandle: observation)
                    progressContinuation?.finish()

                    ref.downloadURL { url, error in
                        if let url {
                            continuation.resume(returning: url)
                        } else {
                            continuation.resume(
                                throwing: StorageError.downloadURLFailed(
                                    underlying: error ?? NSError(domain: "StorageService", code: -1)
                                )
                            )
                        }
                    }
                }

                uploadTask.observe(.failure) { snapshot in
                    uploadTask.removeObserver(withHandle: observation)
                    progressContinuation?.finish()
                    let error = snapshot.error ?? NSError(domain: "StorageService", code: -1)
                    continuation.resume(throwing: StorageError.uploadFailed(underlying: error))
                }
            }
        }

        return (url: urlTask, progress: progressStream)
    }

    // MARK: Download to Local File

    func downloadToLocal(remotePath: String, localURL: URL) async throws {
        let ref = storage.reference().child(remotePath)

        do {
            _ = try await ref.writeAsync(toFile: localURL)
        } catch {
            throw StorageError.downloadFailed(underlying: error)
        }
    }

    // MARK: Delete File

    func deleteFile(path: String) async throws {
        let ref = storage.reference().child(path)

        do {
            try await ref.delete()
        } catch {
            throw StorageError.deleteFailed(underlying: error)
        }
    }
}
