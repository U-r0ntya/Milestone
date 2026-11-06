import Foundation
import Observation

// 投稿の詳細の ViewModel（見ている投稿と、その返信の一覧）
@Observable
@MainActor
final class PostDetailViewModel {
    private(set) var post: Post  // 詳細を見ている投稿　set:書きかえることだけを private にする
    private(set) var isLiked: Bool = false  // いいね済みか
    private(set) var likeCount: Int  // 画面にカウント数を出す変数
    private(set) var isLiking: Bool = false  // いいねの保存中か

    var replies: [Post] = []  // 返信の一覧（古い順）
    var isLoading = false  // 投稿を読み込み中か
    var errorMessage: String? = nil  // エラーメッセージ

    private let repository: PostRepository

    // ほかの ViewModel と同じ2つの init。どの投稿の詳細かを、最初に受け取る
    init(post: Post) {
        self.post = post
        self.repository = FirestorePostRepository()
        likeCount = post.likeCount  // 画面にカウント数を出す変数（初期値は現在の数）
    }

    init(post: Post, repository: PostRepository) {
        self.post = post
        self.repository = repository
        likeCount = post.likeCount  // 画面にカウント数を出す変数（初期値は現在の数）
    }

    // 返信を読み込む
    func loadReplies() async {

        guard !isLoading else { return }  // 読み込み中にもう一度呼ばれたら何もしない

        isLoading = true  // 読み込みを始めた
        defer { isLoading = false }  // この関数を抜けるときに、必ず false に戻す

        errorMessage = nil
        do {
            let fetchedReplies: [Post] = try await repository.fetchReplies(
                postId: post.id
            )
            replies = fetchedReplies  // 成功したら入れる
        } catch {
            errorMessage = "返信を読み込めませんでした。通信状態を確かめて、もう一度試してください。"
            //  失敗したら
        }
    }
    // 投稿を読み直す（返信したあとに、最新の返信数を出すため）
    func reloadPost() async {
        do {
            post = try await repository.fetchPost(id: post.id)  // 投稿ごと更新
            likeCount = post.likeCount  // 数の更新
        } catch {
            // 失敗しても、今の表示のままにする
        }
    }
    // いいねを押しているかどうか
    func loadIsLiked(userId: String) async {
        do {
            isLiked = try await repository.isLiked(
                postId: post.id,
                userId: userId
            )
        } catch {
            // 失敗しても、今の表示のままにする
        }
    }

    // いいねを押した時
    func toggleLike(userId: String) async {
        guard !isLiking else { return }  // 保存中にもう一度呼ばれたら何もしない
        isLiking = true  // 保存を始めた
        defer { isLiking = false }  // この関数を抜けるときに、必ず false に戻す
        // 押す前のハートと数を覚えておき、失敗したら戻す
        let oldCount = likeCount
        let wasLiked = isLiked
        do {
            if !isLiked {  // いいね済みでないなら
                isLiked = true
                likeCount = likeCount + 1
                try await repository.likePost(postId: post.id, userId: userId)
            } else {
                likeCount = likeCount - 1
                isLiked = false
                try await repository.unlikePost(postId: post.id, userId: userId)
            }
        } catch {  // 失敗したら
            likeCount = oldCount
            isLiked = wasLiked

        }
    }
}
