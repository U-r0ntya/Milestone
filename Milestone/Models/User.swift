import Foundation

// ユーザー
struct User: Codable, Identifiable {
    let id: String
    let name: String
    let iconURL: String?
    let device: Device
    let bio: String?
  
}
