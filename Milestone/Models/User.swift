import Foundation

// ユーザー
// - Codable：Firestore に保存する・読むため（プロパティの名前がそのままフィールドの名前になる）
// - Identifiable：id を持っている（ForEach で id: を書かずに使える）
struct User: Codable, Identifiable {
    let id: String
    let name: String
    var favoriteWorldId: String? = nil  // お気に入りのワールドの ID（1つだけ。一覧の一番上に出す）
}
