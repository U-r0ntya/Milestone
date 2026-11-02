import SwiftUI

// 投稿新規作成（タイムラインの＋ボタンから、シートで開く）
struct ComposePostView: View {
    let user: User  // 投稿する人（ログイン中の人）
    let onPosted: () -> Void  // 投稿できたときの処理（タイムラインの読み直し）

    @State private var viewModel = ComposePostViewModel()
    @Environment(\.dismiss) private var dismiss  // シートを閉じるための機能
    @FocusState private var isTextFocused: Bool  // 本文の入力欄にフォーカスがあるか
    // 下書き（アプリを閉じても残る）
    @AppStorage("composeDraftText") private var draftText = ""
    @AppStorage("composeDraftTags") private var draftTags = ""

    // キーボードの上の道具の列（押したときの機能は、あとで作る）
    private var toolRow: some View {
        HStack(spacing: 40) {
            // 画像
            Button {
            } label: {
                Image(systemName: "photo")
            }
            // タグ
            Button {
            } label: {
                Image(systemName: "number")
            }
            // ワールド
            Button {
            } label: {
                Image(systemName: "cube")
            }
            // 座標
            Button {
            } label: {
                Image(systemName: "mappin.and.ellipse")
            }
            // 招待コード
            Button {
            } label: {
                Image(systemName: "globe")
            }
            Spacer()
        }
        .font(.title3)
        .foregroundStyle(Color.accentColor)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.appBackground)
        .overlay(alignment: .top) {
            Divider()
                .overlay(Color.appCardBorder)  // 上に、うすい紫の区切り線
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    // アイコン（今は全員同じ。本物のアイコンはフェーズ7で付ける）
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.appCardBorder)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(.appTextPrimary)

                        // 本文（空のときだけ、うすい文字の案内を出す）
                        ZStack(alignment: .topLeading) {
                            if viewModel.text.isEmpty {
                                Text("いまどうしてる？")
                                    .foregroundStyle(
                                        Color.appTextSecondary.opacity(0.6)
                                    )
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                            TextEditor(text: $viewModel.text)
                                .scrollContentBackground(.hidden)  // TextEditor の白い背景を消す
                                .foregroundStyle(.appTextPrimary)
                                .frame(minHeight: 160, maxHeight: .infinity)
                                .focused($isTextFocused)
                        }
                    }
                }

                // 文字数（300文字をこえたら赤）
                Text(
                    "\(viewModel.trimmedText.count) / \(viewModel.textMaxLength)"
                )
                .font(.caption)
                .foregroundStyle(
                    viewModel.trimmedText.count > viewModel.textMaxLength
                        ? .red : .appTextSecondary
                )
                .frame(maxWidth: .infinity, alignment: .trailing)

                // エラー
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .safeAreaInset(edge: .bottom) {
                toolRow  // 画面の一番下に置く（キーボードが出たら、キーボードのすぐ上に上がる）
            }
            .navigationTitle("新規投稿")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {  // 画面を開いたら実行
                viewModel.text = draftText
                viewModel.tagsText = draftTags
                isTextFocused = true  // 画面が開いたら、本文の入力欄にフォーカスを当てる（キーボードが出る）
            }
            // 入力するたびに下書きに保存する（閉じ方に関係なく、いつも最新が残る）
            .onChange(of: viewModel.text) { _, newValue in
                draftText = newValue
            }
            .onChange(of: viewModel.tagsText) { _, newValue in
                draftTags = newValue
            }.toolbar {
                // 左上：キャンセル（閉じるだけ。下書きを保存するかは、閉じたあとにタイムラインで聞く）
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                // 右上：投稿（押せないときは自動で灰色になる）
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            // 保存できたら、親に知らせてシートを閉じる。失敗したら閉じずにエラーを見せる
                            if await viewModel.post(user: user) {
                                onPosted()
                                viewModel.text = ""
                                viewModel.tagsText = ""
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isPosting {
                            ProgressView()
                        } else {
                            Text("投稿")
                        }
                    }
                    .buttonStyle(.glassProminent)  // 色付きのガラスのボタン
                    .tint(Color.accentColor)  // 色はアプリカラー（エメラルド）
                    .disabled(!viewModel.canPost)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isPosting)  // 保存中は、下にスワイプして閉じられないようにする
    }
}

#Preview {
    ComposePostView(
        user: User(
            id: "preview",
            name: "すてぃーぶ",
            iconURL: nil,
            device: .nintendoSwitch,
            bio: nil
        ),
        onPosted: {}
    )
}
