//
//  ProductImages.swift
//  Project-Portion-demo
//
//  Created by Evgenii Sukhov on 30.01.2026.
//

import SwiftUI
import UIKit
import Foundation

struct ProductLink: Codable {
    let prodID: Int
    let url: String?
}

struct ProductLinkResponse: Codable {
    let success: Bool
    let data: ProductLink?
    let error: String?
}

class ProductLinkService {
    static let shared = ProductLinkService()
    private let baseURL = "http://\(ServerConfig.YourIP):8000"
    private let cache = NSCache<NSString, NSString>()
    
    private init() {}
    
    func fetchProductLink(for prodID: Int) async throws -> String? {
        let cacheKey = "link_\(prodID)" as NSString
        
        // Проверяем кэш
        if let cachedLink = cache.object(forKey: cacheKey) {
            return String(cachedLink)
        }
        
        guard let url = URL(string: "\(baseURL)/product_link/\(prodID)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ProductLinkResponse.self, from: data)
        
        guard response.success, let productLink = response.data else {
            return nil
        }
        
        if let urlString = productLink.url {
            // Кэшируем результат
            cache.setObject(urlString as NSString, forKey: cacheKey)
        }
        
        return productLink.url
    }
}


struct ProductImages {
    static let mapping: [Int: String] = [
        1: "moloko",
        2: "cheese_russian",
        3: "sausage_bavarian",
        4: "chicken_breast",
        5: "greek_yogurt",
        6: "pasta_mushrooms",
        7: "cola",
        8: "brownie_bar",
        9: "pasta",
        10: "bread",
        11: "big_special",
        12: "ice_latte"
    ]
    
    static func imageName(for productID: Int) -> String {
            return mapping[productID] ?? "placeholder"
        }
        
        static func hasLocalImage(for productID: Int) -> Bool {
            return mapping[productID] != nil && mapping[productID] != "placeholder"
        }
}


class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {}
    
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

struct HybridImage: View {
    let prodID: Int
    @State private var productURL: URL? = nil
    
    var body: some View {
        Group {
            if ProductImages.hasLocalImage(for: prodID) {
                // Локальное изображение
                linkedImage(
                    Image(ProductImages.imageName(for: prodID))
                        .resizable()
                )
            } else {
                // Загрузка с сервера
                RemoteImageView(prodID: prodID, productURL: productURL)
            }
        }
        .onAppear {
            loadProductLink()
        }
    }
    
    private func linkedImage(_ image: Image) -> some View {
        Group {
            if let productURL = productURL {
                Link(destination: productURL) {
                    image
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                image
            }
        }
    }
    
    private func loadProductLink() {
        Task {
            do {
                if let urlString = try await ProductLinkService.shared.fetchProductLink(for: prodID),
                   let url = URL(string: urlString) {
                    await MainActor.run {
                        self.productURL = url
                    }
                }
            } catch {
                print("Ошибка загрузки ссылки на продукт: \(error)")
            }
        }
    }
}

struct RemoteImageView: View {
    let prodID: Int
    let productURL: URL?
    @State private var image: UIImage? = nil
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                linkedImage(
                    Image(uiImage: image)
                        .resizable()
                )
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.7)
                    )
                    .onAppear {
                        loadFromServer()
                    }
            }
        }
    }
    
    private func linkedImage(_ image: Image) -> some View {
        Group {
            if let productURL = productURL {
                Link(destination: productURL) {
                    image
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                image
            }
        }
    }
    
    private func loadFromServer() {
        isLoading = true
        
        let cacheKey = "prod_\(prodID)"
        
        if let cachedImage = ImageCache.shared.get(forKey: cacheKey) {
            self.image = cachedImage
            return
        }
        
        let url = URL(string: "http://\(ServerConfig.YourIP):8000/image/\(prodID)")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let data = data, let uiImage = UIImage(data: data) {

                    ImageCache.shared.set(uiImage, forKey: cacheKey)
                    self.image = uiImage
                }
            }
        }.resume()
    }
}
