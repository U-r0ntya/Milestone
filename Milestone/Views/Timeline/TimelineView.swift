import SwiftUI

// タイムライン：投稿の一覧（新しい順）と、投稿ボタン
struct TimelineView: View {
    let user: User
    @State private var viewModel = TimelineViewModel()

    @State private var isBottomRefreshing = false  // 下の更新の途中かどうか
    @State private var isShowingCompose = false  // 投稿の画面を開いているか
    @AppStorage("composeDraftText") private var draftText = ""  // 投稿の画面と同じ名前（キー）なので、同じ下書きを読む
    @AppStorage("composeDraftTags") private var draftTags = ""
    @State private var isShowingDraftDialog = false  // 真ん中のカードを出しているか

    var body: some View {
        // 一覧の上に、右下の投稿ボタンを重ねる
        ZStack(alignment: .bottomTrailing) {
            content

            // 投稿ボタン（投稿新規作成の画面を開く）
            Button {
                isShowingCompose = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 16)
        }
        .task {
            await viewModel.loadPosts()  // 画面を開いたときに読み込む
        }
        .sheet(
            isPresented: $isShowingCompose,
            onDismiss: {
                // 閉じたあとに本文が残っていたら（キャンセル・スワイプ）、保存するか聞く
                if !draftText.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
                {
                    isShowingDraftDialog = true
                }
            }
        ) {
            ComposePostView(user: user) {
                Task { await viewModel.loadPosts() }
            }
        }
        .overlay {
            if isShowingDraftDialog {
                DraftSaveDialog(
                    onSave: {
                        isShowingDraftDialog = false  // 下書きはもう保存されているので、閉じるだけ
                    },
                    onDelete: {
                        draftText = ""  // 下書きを消す
                        draftTags = ""
                        isShowingDraftDialog = false
                    }
                )
            }
        }
    }

    // 投稿があるか・読み込み中か・エラーかで、出すものを切り替える
    @ViewBuilder
    private var content: some View {
        if !viewModel.posts.isEmpty {
            // 投稿の一覧
            ScrollView {
                LazyVStack(spacing: 12) {
                    // 引っ張って更新に失敗したときは、前の投稿を残して上にエラーを出す
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ForEach(viewModel.posts) { post in
                        PostRowView(post: post)
                    }

                    // 一番下の目印：画面に入ったら更新する（くるくるもここに出す）
                    ProgressView()
                        .frame(height: 32)
                        .opacity(isBottomRefreshing ? 1 : 0)  // 場所はいつも取っておいて、更新中だけ見せる
                        .onAppear {
                            guard !isBottomRefreshing else { return }
                            Task {
                                isBottomRefreshing = true  // くるくるを見せる
                                await viewModel.loadPosts()
                                isBottomRefreshing = false  // 取得が終わったら隠す
                            }
                        }
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)
                .padding(.bottom, 72)
            }
            .refreshable {
                await viewModel.loadPosts()  // 引っ張って更新
            }

        } else if viewModel.isLoading {
            // 初めての読み込み中
            ProgressView()
        } else if let errorMessage = viewModel.errorMessage {
            // 1件も読めずに失敗した
            ContentUnavailableView {
                Label("読み込めませんでした", systemImage: "wifi.exclamationmark")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("もう一度読み込む") {
                    Task { await viewModel.loadPosts() }
                }
                .buttonStyle(.primary)
            }
        } else {
            // 投稿が0件
            ContentUnavailableView(
                "まだ投稿がありません",
                systemImage: "text.bubble",
                description: Text("右下のボタンから、最初の投稿をしてみよう")
            )
        }
    }
}

#Preview {
    NavigationStack {
        TimelineView(
            user: User(
                id: "preview",
                name: "すてぃーぶ",
                iconURL: nil,
                device: .nintendoSwitch,
                bio: nil
            )
        )
        .appHeader("タイムライン")
    }
}
