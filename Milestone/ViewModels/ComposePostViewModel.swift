import Foundation
import Observation

@Observable
@MainActor
final class ComposePostViewModel {
    // 画面が見る値
    var text = ""  // 本文
    var isPosting = false  // 保存中か
    var errorMessage: String? = nil

    var tagInput = ""  // タグの入力欄の文字
    var selectedTags: [String] = []  // 付けたタグ（投稿に入れるもの）

    let tagMaxCount = 5  // 付けられるタグの最大数
    let textMaxLength = 300  // 本文の最大文字数

    // タグの入力欄の前後の空白と、前後の「#」を取り除いたもの（「 #建築 」→「建築」）
    var trimmedTagInput: String {
        tagInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#＃"))
    }

    // 「追加」を押せるか（空ではない・まだ5個に届いていない・同じタグがまだない）
    var canAddTag: Bool {
        !trimmedTagInput.isEmpty
            && selectedTags.count < tagMaxCount
            && !selectedTags.contains(trimmedTagInput)
    }

    // タグを追加する
    func addTag() {
        guard canAddTag else { return }
        selectedTags.append(trimmedTagInput)  // 付けたタグの後ろに足す
        tagInput = ""  // 入力欄を空にする
    }

    // タグを外す（同じ名前のものを消す）
    func removeTag(_ tag: String) {
        selectedTags.removeAll { $0 == tag }

    }

    private let repository: PostRepository

    private let replyToPostId: String?

    // AuthViewModel・TimelineViewModel と同じ2つの init
    init(replyToPostId: String? = nil) {
        self.repository = FirestorePostRepository()
        self.replyToPostId = replyToPostId
    }

    init(repository: PostRepository, replyToPostId: String? = nil) {
        self.repository = repository
        self.replyToPostId = replyToPostId
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
            id: UUID().uuidString,  // 投稿の ID をここで作る（毎回ちがう文字列になる）
            userId: user.id,
            replyToPostId: replyToPostId,
            text: trimmedText,
            imageURLs: [],  // 画像はあとで
            createdAt: Date(),  // 今の日時
            tags: selectedTags,  // 付けたタグ
            replyCount: 0,
            likeCount: 0,
            userName: user.name,  // ログイン中の人の情報をコピー
            userIconURL: user.iconURL,
            version: nil,  // バージョン・シード値・参加方法はあとで
            device: user.device,
            seed: nil,
            realmsCode: nil,
            serverAddress: nil,
            xboxGamertag: nil
        )
        do {
            // 保存する
            if let parentId = newPost.replyToPostId {
                try await repository.saveReply(
                    newPost,
                    parentId: parentId
                )
            } else {
                try await repository.savePost(newPost)
            }
            return true

        } catch {
            errorMessage =
                (replyToPostId == nil
                    ? "投稿を保存できませんでした。\n通信状態を確かめて、もう一度試してください。"
                    : "返信を保存できませんでした。\n通信状態を確かめて、もう一度試してください。")
            return false
        }
    }
}
