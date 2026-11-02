import Foundation
import Observation  // @Observable を使うため（AuthViewModel は SwiftUI の import で入っていた）

@Observable
@MainActor
final class TimelineViewModel {
    // 画面が見る値
    var posts: [Post] = []
    var isLoading = false
    var errorMessage: String? = nil

    private let repository: PostRepository

    // AuthViewModel と同じ2つの init（理由も同じで、MainActor の都合）
    init() {
        self.repository = FirestorePostRepository()
    }

    init(repository: PostRepository) {
        self.repository = repository
    }

    func loadPosts() async {

        guard !isLoading else { return }  // 読み込み中にもう一度呼ばれたら何もしない

        isLoading = true  // 読み込みを始めた
        defer { isLoading = false }  // この関数を抜けるときに、必ず false に戻す

        errorMessage = nil
        do {
            let fetchedPosts: [Post] = try await repository.fetchTimeline()  // ①取ってくる
            posts = fetchedPosts  // ② 成功したら入れる
        } catch {
            errorMessage = "投稿を読み込めませんでした。通信状態を確かめて、もう一度試してください。"  //  失敗したら
        }

    }
}
