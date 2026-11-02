import Foundation
import Observation  // @Observable を使うため（AuthViewModel は SwiftUI の import で入っていた）

@Observable
@MainActor
final class TimelineViewModel {
    // 画面が見る値
    var posts: [Post] = []
    var isLoading = false
    var errorMessage: String? = nil

    var hasMore = true  // まだ古い投稿の続きがあるか
    var isLoadingMore = false  // 続きを読み込み中か（一番下のくるくるに使う）

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
            let fetchedPosts: [Post] = try await repository.fetchTimeline()  // 取ってくる
            posts = fetchedPosts  // 成功したら入れる
            hasMore = true  // 最新を取り直したので、また続きを読めるようにする
        } catch {
            errorMessage = "投稿を読み込めませんでした。通信状態を確かめて、もう一度試してください。"  //  失敗したら
        }

    }
    // 一番下まで来たら、今の一覧より古い投稿の続きを読み込んで、下に足す
    func loadMorePosts() async {
        // 読み込み中・続きがないときは、何もしない
        guard !isLoading && !isLoadingMore && hasMore else { return }  // 読み込み中にもう一度呼ばれたら何もしない
        // 今の一覧の、一番古い投稿の日時を取り出す
        guard let oldestDate = posts.last?.createdAt else { return }
        // 続きの読み込み中にして、終わったら戻す
        isLoadingMore = true  // 読み込みを始めた
        defer { isLoadingMore = false }
        errorMessage = nil
        do {
            var cursor = oldestDate                   // ここより古いものを取ってくる（目印の日時）
            let existingIDs = Set(posts.map(\.id))    // 今の一覧にある投稿の ID

            // 新しい投稿が1件以上取れるまで、古いほうへ取りに行く
            while true {
                let fetched = try await repository.fetchOlderPosts(before: cursor)

                // Firestore から1件も来ない、または目印が前に進まない（同じものしか来ない）なら、もう続きはない
                guard let last = fetched.last, last.createdAt < cursor else {
                    hasMore = false
                    break
                }

                // 返信と、すでに一覧にある投稿を除く（日時の小さなずれで、目印の投稿そのものが来ることがあるため）
                let newPosts = fetched.filter { !$0.isReply && !existingIDs.contains($0.id) }
                cursor = last.createdAt               // 次は、今回の一番古いもの（返信も含む）より前を取る

                if !newPosts.isEmpty {
                    posts += newPosts                 // 新しい投稿が取れたら、下に足して終わり
                    break
                }
                // 返信や、もうある投稿だけだったときは、さらに古いほうを取りに行く
            }
        } catch {
            errorMessage = "続きを読み込めませんでした。通信状態を確かめて、もう一度試してください。"
        }
    }
}
