import SwiftUI

// 投稿の詳細：投稿の全体と、その投稿への返信の一覧（古い順）
// 返信を書く・いいねを押すのはフェーズ5で作る
struct PostDetailView: View {
    let user: User  // 返信する人（ログイン中の人）

    @State private var viewModel: PostDetailViewModel

    // どの投稿の詳細かを受け取って、その投稿用の ViewModel を作る
    init(user: User, post: Post) {
        self.user = user
        _viewModel = State(initialValue: PostDetailViewModel(post: post))
    }

    // プレビュー用（Firestore を使わない Repository を渡せる）
    init(user: User, post: Post, repository: PostRepository) {
        self.user = user
        _viewModel = State(
            initialValue: PostDetailViewModel(
                post: post,
                repository: repository
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                postSection

                Divider()
                    .overlay(Color.appCardBorder)  // うすい紫の区切り線

                // 返信の見出し
                Text("返信 \(viewModel.replies.count)件")
                    .font(.subheadline.bold())
                    .foregroundStyle(.appTextPrimary)

                repliesSection
            }
            .padding(16)
        }
        .refreshable {
            await viewModel.loadReplies()  // 引っ張って返信を読み直す
        }
        .task {
            await viewModel.loadReplies()  // 画面を開いたときに返信を読み込む
        }
        .appHeader("投稿")
    }

    // 投稿の全体（タイムラインのカードより大きく、全部の情報を出す）
    private var postSection: some View {
        let post = viewModel.post

        return VStack(alignment: .leading, spacing: 12) {
            // アイコン・名前・機種
            HStack(spacing: 12) {
                // アイコン（今は全員同じ。本物のアイコンはフェーズ7で付ける）
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(.appCardBorder)

                VStack(alignment: .leading, spacing: 4) {
                    Text(post.userName)
                        .font(.headline)
                        .foregroundStyle(.appTextPrimary)

                    // 機種が入っているときだけ、ラベルを出す
                    if let device = post.device {
                        Text(device.displayName)
                            .font(.caption2.bold())
                            .foregroundStyle(.appTagText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.appTagBackground)
                            .clipShape(Capsule())
                    }
                }
            }

            // 本文（大きめの文字で全部出す）
            Text(post.text)
                .font(.body)
                .foregroundStyle(.appTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)  // 長押しでコピーできる

            // タグ（全部出す。多いときは横にスクロール）
            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(post.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.footnote)
                                .foregroundStyle(.appTextSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            Color.appCardBorder,
                                            lineWidth: 1
                                        )  // うすい紫の枠
                                )
                        }
                    }
                    .padding(1)  // 枠線のはしが切れないように
                }
            }

            // 投稿した日時（「2026年11月2日 18:48」の形）
            Text(
                post.createdAt.formatted(
                    .dateTime.year().month().day().hour().minute()
                        .locale(Locale(identifier: "ja_JP"))
                )
            )
            .font(.caption)
            .foregroundStyle(.appTextSecondary)

            // 返信数・いいね数（今は表示だけ。押せるのはフェーズ5）
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                    Text("\(post.replyCount)")
                }
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                    Text("\(post.likeCount)")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.appTextSecondary)
        }
    }

    // 返信の一覧（読み込み中・エラー・0件・一覧で出すものを切り替える）
    @ViewBuilder
    private var repliesSection: some View {
        if !viewModel.replies.isEmpty {
            // 返信の一覧（タイムラインと同じカードを使う）
            LazyVStack(spacing: 12) {
                ForEach(viewModel.replies) { reply in
                    PostRowView(post: reply)
                }
            }
        } else if viewModel.isLoading {
            // 読み込み中
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
        } else if let errorMessage = viewModel.errorMessage {
            // 読み込めなかった
            VStack(spacing: 12) {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                Button("もう一度読み込む") {
                    Task { await viewModel.loadReplies() }
                }
                .buttonStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
        } else {
            // 返信が0件
            Text("まだ返信はありません")
                .font(.footnote)
                .foregroundStyle(.appTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
        }
    }
}

#Preview {
    NavigationStack {
        PostDetailView(
            user: User(
                id: "preview",
                name: "すてぃーぶ",
                iconURL: nil,
                device: .nintendoSwitch,
                bio: nil
            ),
            post: Post(
                id: "preview1",
                userId: "user1",
                replyToPostId: nil,
                text: "拠点の横に村ができてた！交易所にしたい",
                imageURLs: [],
                createdAt: Date().addingTimeInterval(-3 * 60 * 60),  // 今から3時間前
                tags: ["建築", "サバイバル", "村", "交易所", "スポーン付近"],
                replyCount: 0,
                likeCount: 5,
                userName: "すてぃーぶ",
                userIconURL: nil,
                version: "1.21.40",
                device: .nintendoSwitch,
                seed: nil,
                realmsCode: nil,
                serverAddress: nil,
                xboxGamertag: nil
            ),
            repository: MockAPIPostRepository()  // プレビューでは Firestore を使わない（返信は0件）
        )
    }
}
