import Foundation

// いいね
struct Like: Codable {
    let userId: String  // いいねした人のユーザー ID
    let createdAt: Date  // いいねした日時
    let postId: String  // いいねした投稿の ID
}
