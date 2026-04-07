import Foundation

/// Simple TTL-based in-memory cache for API responses.
final class APICache: @unchecked Sendable {

    private struct Entry {
        let value: Any
        let expiry: Date
    }

    private var store: [String: Entry] = [:]
    private let lock = NSLock()

    func get<T>(_ key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }

        guard let entry = store[key] else { return nil }
        if Date() > entry.expiry {
            store.removeValue(forKey: key)
            return nil
        }
        return entry.value as? T
    }

    func set(_ key: String, value: Any, ttl: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }

        store[key] = Entry(value: value, expiry: Date().addingTimeInterval(ttl))
    }

    func invalidate(prefix: String) {
        lock.lock()
        defer { lock.unlock() }

        store = store.filter { !$0.key.hasPrefix(prefix) }
    }

    func invalidateAll() {
        lock.lock()
        defer { lock.unlock() }

        store.removeAll()
    }
}
