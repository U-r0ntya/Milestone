import Foundation

// 投稿（返信も同じ型）
struct Post: Codable, Identifiable {
    let id: String
    let userId: String
    let replyToPostId: String?
    let text: String
    let imageURLs: [String]
    let createdAt: Date
    let tags: [String]
    let replyCount: Int
    let likeCount: Int
    let userName: String
    let userIconURL: String?
    let version: String?
    let device: Device?
    let seed: Int64?
    let realmsCode: String?
    let serverAddress: String?
    let xboxGamertag: String?

    // 返信かどうか（返信先の ID があれば返信）
    var isReply: Bool {
        replyToPostId != nil
    }

    // 参加方法が1つでも入っているか（注意書きを出す条件）
    var hasJoinInfo: Bool {
        realmsCode != nil || serverAddress != nil || xboxGamertag != nil
    }
}
