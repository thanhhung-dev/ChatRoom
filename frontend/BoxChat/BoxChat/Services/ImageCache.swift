//
//  ImageCache.swift
//  BoxChat
//
//  NSCache-based image caching with async loading.
//  Replaces raw URLSession.dataTask calls scattered throughout the app.
//

import UIKit

final class ImageCache {

    static let shared = ImageCache()

    private let cache   = NSCache<NSString, UIImage>()
    private let session: URLSession

    private init() {
        cache.countLimit    = 200
        cache.totalCostLimit = 100 * 1024 * 1024  // 100 MB

        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,   // 50 MB memory
            diskCapacity: 200 * 1024 * 1024      // 200 MB disk
        )
        session = URLSession(configuration: config)
    }

    // MARK: - Core API

    /// Load an image from cache or network.
    /// Returns the data task so callers can cancel it (e.g., on cell reuse).
    @discardableResult
    func load(from url: URL,
              completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        let key = url.absoluteString as NSString

        // Memory cache hit
        if let cached = cache.object(forKey: key) {
            completion(cached)
            return nil
        }

        let task = session.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self?.cache.setObject(image, forKey: key, cost: data.count)
            DispatchQueue.main.async { completion(image) }
        }
        task.resume()
        return task
    }

    // MARK: - UIImageView Convenience

    /// Load an image directly into a UIImageView with optional cross-dissolve.
    @discardableResult
    func loadInto(_ imageView: UIImageView,
                  from url: URL?,
                  placeholder: UIImage? = nil,
                  fade: Bool = true) -> URLSessionDataTask? {
        imageView.image = placeholder

        guard let url else { return nil }

        let key = url.absoluteString as NSString
        if let cached = cache.object(forKey: key) {
            imageView.image = cached
            return nil
        }

        return load(from: url) { [weak imageView] image in
            guard let imageView, let image else { return }
            if fade {
                UIView.transition(with: imageView, duration: 0.2,
                                  options: .transitionCrossDissolve) {
                    imageView.image = image
                }
            } else {
                imageView.image = image
            }
        }
    }

    // MARK: - Cache Management

    /// Evict all cached images
    func clearMemoryCache() {
        cache.removeAllObjects()
    }

    /// Remove a single cached image for a given URL
    func remove(for url: URL) {
        let key = url.absoluteString as NSString
        cache.removeObject(forKey: key)
    }

    /// Check if an image is already cached in memory
    func hasCachedImage(for url: URL) -> Bool {
        cache.object(forKey: url.absoluteString as NSString) != nil
    }

    /// Retrieve a cached image without triggering a download
    func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url.absoluteString as NSString)
    }
}
