import FirebaseFirestore
import Foundation

// 投稿を取ってくる係の「約束」（protocol）
// 仮の API でも Firebase でも、この約束どおりに作れば画面からは同じように使える
protocol PostRepository {
    func fetchTimeline() async throws -> [Post]
    func fetchOlderPosts(before date: Date) async throws -> [Post]  // ← 追加：この日時より古い投稿を取ってくる
    func fetchReplies(postId: String) async throws -> [Post]
    func savePost(_ post: Post) async throws
    // 返信を保存し、元の投稿の replyCount を 1 増やす
    func saveReply(_ reply: Post, parentId: String) async throws
    func fetchPost(id: String) async throws -> Post
    // いいねをする
    func likePost(postId: String, userId: String) async throws
    // いいねを取り消す
    func unlikePost(postId: String, userId: String) async throws
    // いいね済みか調べる
    func isLiked(postId: String, userId: String) async throws -> Bool

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
    func saveReply(_ reply: Post, parentId: String) async throws {
        // Mock は保存しない（savePost と同じ扱い）
    }
    // Gist は1件だけ取れないので、全部取ってから ID が同じものを探す
    func fetchPost(id: String) async throws -> Post {
        let posts = try await fetchTimeline()
        guard let post = posts.first(where: { $0.id == id }) else {
            throw URLError(.badServerResponse)  // 見つからなかった
        }
        return post
    }
    func likePost(postId: String, userId: String) async throws {}
    func unlikePost(postId: String, userId: String) async throws {}
    func isLiked(postId: String, userId: String) async throws -> Bool {
        return false
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
    func saveReply(_ reply: Post, parentId: String) async throws {
        // 返信を書き込む予定に入れる
        let batch = db.batch()

        // 返信を書き込む場所を決める（まだ通信しない）
        let replyRef = db.collection("posts").document(reply.id)
        // from:何を書くか、forDocument:どこのドキュメントに書くか
        try batch.setData(from: reply, forDocument: replyRef)

        // 元の投稿の replyCount を +1 する予定に入れる
        let parentRef = db.collection("posts").document(parentId)
        //.updateData:この辞書に書いたフィールドだけを書きかえ
        // FieldValue.increment(...):今の値に足す(increment の引数の型は Int64)
        batch.updateData(
            ["replyCount": FieldValue.increment(Int64(1))],
            forDocument: parentRef
        )

        // 予定に入れた2つを、まとめて書き込む
        try await batch.commit()
    }
    func fetchPost(id: String) async throws -> Post {
        // document(id) で場所を作る（通信しない）
        let idRef = db.collection("posts").document(id)
        // getDocument() で読む（通信する → try await）
        let snapshot = try await idRef.getDocument()
        // data(as: Post.self) で Post に変えて返す（通信しない、変換が失敗するかも → try だけ）
        return try snapshot.data(as: Post.self)
    }
    // postId: いいねした投稿のID, userId: いいねした人のユーザーID
    func likePost(postId: String, userId: String) async throws {
        let like = Like(userId: userId, createdAt: Date(), postId: postId)
        let batch = db.batch()

        // この投稿に、だれがいいねしたか
        let postLikeRef = db.collection("posts").document(postId).collection(
            "likes"
        ).document(userId)
        // from:何を書くか、forDocument:どこのドキュメントに書くか
        try batch.setData(from: like, forDocument: postLikeRef)

        // この人が、どの投稿にいいねしたか
        let userLikeRef = db.collection("users").document(userId).collection(
            "likes"
        )
        .document(postId)
        // from:何を書くか、forDocument:どこのドキュメントに書くか
        try batch.setData(from: like, forDocument: userLikeRef)

        // 投稿の likeCount を +1 する予定に入れる
        batch.updateData(
            ["likeCount": FieldValue.increment(Int64(1))],
            forDocument: db.collection("posts").document(postId)
        )

        try await batch.commit()
    }

    func unlikePost(postId: String, userId: String) async throws {
        let batch = db.batch()

        // この投稿に、だれがいいねしたか
        let postLikeRef = db.collection("posts").document(postId).collection(
            "likes"
        ).document(userId)
        // deleteDocument(場所)：指定の場所を消す
        batch.deleteDocument(postLikeRef)

        // この人が、どの投稿にいいねしたか
        let userLikeRef = db.collection("users").document(userId).collection(
            "likes"
        )
        .document(postId)
        // deleteDocument(場所)：指定の場所を消す
        batch.deleteDocument(userLikeRef)
        // 投稿の likeCount を -1 する予定に入れる
        batch.updateData(
            ["likeCount": FieldValue.increment(Int64(-1))],
            forDocument: db.collection("posts").document(postId)
        )

        try await batch.commit()
    }
    // ドキュメントがあれば、いいね済み
    func isLiked(postId: String, userId: String) async throws -> Bool {
        let userLikeRef = db.collection("users").document(userId).collection(
            "likes"
        )
        .document(postId)
        // 場所を読み取る
        let userSnapshot = try await userLikeRef.getDocument()
        // 読み取った場所があるかないか
        return userSnapshot.exists
    }
}
