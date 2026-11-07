import Foundation

// いいね（投稿の下と、ユーザーの下の2か所に同じ形で保存する）
// - Codable：Firestore に保存するため（プロパティの名前がそのままフィールドの名前になる）
// - 一覧の ForEach や NavigationLink で使わないので、Identifiable・Hashable は付けていない
struct Like: Codable {
    let userId: String  // いいねした人のユーザー ID
    let createdAt: Date  // いいねした日時
    let postId: String  // いいねした投稿の ID
}
