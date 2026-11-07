import Foundation

// 投稿（返信も同じ型。返信は replyToPostId に返信先の ID が入る）
// - Codable：Gist の JSON や Firestore と変換するため（プロパティの名前がそのままフィールドの名前になる）
// - Identifiable：id を持っている。タイムラインの ForEach で id: を書かずに使える
// - Hashable：同じかどうかを速く比べられる。カードから詳細へ NavigationLink(value:) で進むのに使う
struct Post: Codable, Identifiable, Hashable {
    let id: String  // 投稿 ID（アプリが自動で入れる）
    let userId: String  // 書いた人のユーザー ID（uid）
    let replyToPostId: String?  // 返信先の投稿 ID（返信のときだけ入る。普通の投稿は nil）
    let text: String  // 文章（1〜300 文字）
    let imageURLs: [String]  // 画像の URL（Storage。最大 4 枚）
    let createdAt: Date  // 投稿日時（新しい順に並べるのに使う）
    let tags: [String]  // タグ（5 個まで）
    let replyCount: Int  // 返信数（返信で +1）
    let likeCount: Int  // いいね数（いいねで +1、取り消しで -1）
    let userName: String  // ユーザー名（User からコピー。名前を変えても昔の投稿は古い名前のまま）
    let userIconURL: String?  // ユーザーアイコンの URL（User からコピー）
    let version: String?  // バージョン（World から、または入力。「1.21.40」の形）
    let device: Device?  // 機種（World から、または入力）
    let seed: Int64?  // シード値（付けるかは本人が選ぶ）
    let realmsCode: String?  // Realms の招待コード（返信には付けられない）
    let serverAddress: String?  // サーバーのアドレス（ポート番号まで含める）
    let xboxGamertag: String?  // Xbox のゲーマータグ

    // 返信かどうか（返信先の ID があれば返信）
    var isReply: Bool {
        replyToPostId != nil
    }

    // 参加方法が1つでも入っているか（注意書きを出す条件）
    var hasJoinInfo: Bool {
        realmsCode != nil || serverAddress != nil || xboxGamertag != nil
    }
}
