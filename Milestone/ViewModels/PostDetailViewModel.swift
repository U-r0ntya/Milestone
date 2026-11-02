import Foundation
import Observation

// 投稿の詳細の ViewModel（見ている投稿と、その返信の一覧）
@Observable
@MainActor
final class PostDetailViewModel {
    let post: Post  // 詳細を見ている投稿（変わらないので let）
    var replies: [Post] = []  // 返信の一覧（古い順）
    var isLoading = false  // 読み込み中か
    var errorMessage: String? = nil

    private let repository: PostRepository

    // ほかの ViewModel と同じ2つの init。どの投稿の詳細かを、最初に受け取る
    init(post: Post) {
        self.post = post
        self.repository = FirestorePostRepository()
    }

    init(post: Post, repository: PostRepository) {
        self.post = post
        self.repository = repository
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
}
