import FirebaseFirestore
import Foundation

// 投稿を取ってくる係の「約束」（protocol）
// 仮の API でも Firebase でも、この約束どおりに作れば画面からは同じように使える
protocol PostRepository {
    func fetchTimeline() async throws -> [Post]
    func fetchOlderPosts(before date: Date) async throws -> [Post]  // ← 追加：この日時より古い投稿を取ってくる
    func fetchReplies(postId: String) async throws -> [Post]
    func savePost(_ post: Post) async throws
}

// 仮の API（Gist に置いた JSON）から取ってくる係
struct MockAPIPostRepository: PostRepository {
    // Gist の Raw の URL（版の部分を消した、いつも最新を読む URL）
    let url = URL(
        string:
            "https://gist.githubusercontent.com/U-r0ntya/8f58b8cc0e8cb733d6c09938ae56c2a7/raw/posts.json"
    )!

    // Gist には書き込めないので、何もしない
    func savePost(_ post: Post) async throws {}

    func fetchTimeline() async throws -> [Post] {
        // 1. URL から JSON を取ってくる
        let (data, response) = try await URLSession.shared.data(from: url)

        // 2. うまく取れたか確かめる（200番台なら成功）
        guard let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }

        // 3. JSON を Post の配列に変える
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601  // "2026-10-28T10:00:00Z" を Date に変える
        let posts = try decoder.decode([Post].self, from: data)

        // 4. タイムラインには返信を出さず、新しい順に並べる
        return
            posts
            .filter { !$0.isReply }
            .sorted { $0.createdAt > $1.createdAt }
    }
    // 今は使っていないので、返信はなし
    func fetchReplies(postId: String) async throws -> [Post] {
        []
    }
    // Gist は全部を1回で返すので、続きはない
    func fetchOlderPosts(before date: Date) async throws -> [Post] {
        []
    }
}

// Firestore から取ってくる係
struct FirestorePostRepository: PostRepository {
    let db = Firestore.firestore()

    func fetchTimeline() async throws -> [Post] {
        // posts を新しい順に50件取ってくる（決まった形）
        let snapshot = try await db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()

        // 1件ずつ Post に変える
        let fetchedPosts = try snapshot.documents.map {
            try $0.data(as: Post.self)
        }
        // 返信を除いて返す
        return
            fetchedPosts
            .filter { !$0.isReply }
    }

    func savePost(_ post: Post) async throws {
        // 場所を決める
        let ref = db.collection("posts").document(post.id)
        // 書く
        try ref.setData(from: post)
    }

    func fetchReplies(postId: String) async throws -> [Post] {
        // この投稿への返信だけを取ってくる（決まった形）
        let snapshot = try await db.collection("posts")
            .whereField("replyToPostId", isEqualTo: postId)
            .getDocuments()

        // 1件ずつ Post に変える
        let fetchedReplies = try snapshot.documents.map {
            try $0.data(as: Post.self)
        }
        // 古い順に並べて返す
        return fetchedReplies.sorted { $0.createdAt < $1.createdAt }
    }
    func fetchOlderPosts(before date: Date) async throws -> [Post] {
        // date より古い投稿を、新しい順に50件取ってくる
        let snapshot = try await db.collection("posts")
            .whereField("createdAt", isLessThan: date)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()

        // 1件ずつ Post に変える
        let fetchedPosts = try snapshot.documents.map {
            try $0.data(as: Post.self)
        }
        // 返信も含めたまま返す（返信を除くのは ViewModel でする。
        // 返信だけの回があっても「もう続きがない」とまちがえないように、返信の日時も使うため）
        return fetchedPosts
    }
}
