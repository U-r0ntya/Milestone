import Foundation
import Observation

@Observable
@MainActor
final class ComposePostViewModel {
    // 画面が見る値
    var text = ""                    // 本文
    var isPosting = false            // 保存中か
    var errorMessage: String? = nil

    let textMaxLength = 300          // 本文の最大文字数

    private let repository: PostRepository

    // AuthViewModel・TimelineViewModel と同じ2つの init
    init() {
        self.repository = FirestorePostRepository()
    }

    init(repository: PostRepository) {
        self.repository = repository
    }

    // 本文の前後の空白を取り除いたもの
    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // 投稿ボタンを押せるか
    var canPost: Bool {
        !trimmedText.isEmpty && trimmedText.count <= textMaxLength && !isPosting
    }

    // 投稿する
    func post(user: User) async -> Bool {
        guard canPost else { return false }
        isPosting = true  // 保存を始めた
        defer { isPosting = false }  // この関数を抜けるときに、必ず false に戻す
        errorMessage = nil
        let newPost = Post(
            id: UUID().uuidString,             // 投稿の ID をここで作る（毎回ちがう文字列になる）
            userId: user.id,
            replyToPostId: nil,                // 返信ではない
            text: trimmedText,
            imageURLs: [],                     // 画像はあとで
            createdAt: Date(),                 // 今の日時
            tags: [],  // タグはあとで（タグの入力を作るときに入れる）
            replyCount: 0,
            likeCount: 0,
            userName: user.name,               // ログイン中の人の情報をコピー
            userIconURL: user.iconURL,
            version: nil,                      // バージョン・シード値・参加方法はあとで
            device: user.device,
            seed: nil,
            realmsCode: nil,
            serverAddress: nil,
            xboxGamertag: nil
        )
        do {
            // 保存する
            try await repository.savePost(newPost)
            return true
            
        } catch {
            errorMessage = "投稿を保存できませんでした。通信状態を確かめて、もう一度試してください。"
            return false
        }
    }
}
