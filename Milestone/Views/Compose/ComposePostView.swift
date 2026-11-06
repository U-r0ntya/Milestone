import SwiftUI

// 投稿新規作成（タイムラインの＋ボタンから、シートで開く）
struct ComposePostView: View {
    let user: User  // 投稿する人（ログイン中の人）
    let replyTo: Post?  // 投稿元を持つプロパティ（nil なら新規投稿）
    let onPosted: () -> Void  // 投稿できたときの処理（タイムラインの読み直し）

    @State private var viewModel: ComposePostViewModel
    @Environment(\.dismiss) private var dismiss  // シートを閉じるための機能
    @FocusState private var isTextFocused: Bool  // 本文の入力欄にフォーカスがあるか
    @FocusState private var isTagFocused: Bool  // タグの入力欄にフォーカスがあるか
    @State private var isShowingTagInput = false  // タグの入力欄を出しているか
    // 下書き（アプリを閉じても残る）
    @AppStorage private var draftText: String

    init(user: User, replyTo: Post? = nil, onPosted: @escaping () -> Void) {
        self.user = user
        self.replyTo = replyTo
        self.onPosted = onPosted
        _viewModel = State(
            initialValue: ComposePostViewModel(replyToPostId: replyTo?.id)
        )
        _draftText = AppStorage(wrappedValue: "", Self.draftKey(for: replyTo))
    }

    static func draftKey(for replyTo: Post?) -> String {
        if let replyTo {
            // 返信先の投稿ごとに下書きを登録しておく
            return "replyDraft_\(replyTo.id)"

        } else {
            // 投稿するだけなので、登録先は一つ
            return "composeDraftText"
        }
    }

    // キーボードの上の道具の列（押したときの機能は、あとで作る）
    private var toolRow: some View {
        HStack(spacing: 40) {
            // 画像
            Button {
            } label: {
                Image(systemName: "photo")
            }
            // タグ（押すたびに、タグの入力欄を出す・隠す）
            Button {
                isShowingTagInput.toggle()
                if isShowingTagInput {
                    isTagFocused = true  // 出したら、タグの入力欄にフォーカス
                } else {
                    isTextFocused = true  // 隠したら、本文の入力欄に戻す
                }
            } label: {
                Image(
                    systemName: isShowingTagInput
                        ? "number.circle.fill" : "number"
                )  // 出しているあいだは塗りつぶし
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

    // タグの入力欄（タグボタンを押すと、道具の列のすぐ上に出る）
    private var tagInputRow: some View {
        HStack(spacing: 12) {
            TextField("タグを入力（例：建築）", text: $viewModel.tagInput)
                .focused($isTagFocused)
                .submitLabel(.done)  // キーボードの改行キーを「完了」にする
                .onSubmit {
                    viewModel.addTag()
                    isTagFocused = true  // 続けて入力できるように、入力欄から外さない
                }
                .foregroundStyle(.appTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.appCard)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.appCardBorder, lineWidth: 1)  // うすい紫の枠
                )

            // 付けた数（例：2/5）
            Text("\(viewModel.selectedTags.count)/\(viewModel.tagMaxCount)")
                .font(.caption)
                .foregroundStyle(.appTextSecondary)

            // 追加（押せないときは自動で灰色になる）
            Button("追加") {
                viewModel.addTag()
            }
            .buttonStyle(.glassProminent)
            .tint(Color.accentColor)
            .disabled(!viewModel.canAddTag)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.appBackground)
        .overlay(alignment: .top) {
            Divider()
                .overlay(Color.appCardBorder)  // 上に、うすい紫の区切り線
        }
    }

    // 返信先の投稿（返信のときだけ、本文の入力欄の上に出す。詳細画面の投稿と同じ形）
    private func replySourceSection(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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

            // 本文（3行まで。4行目からは「…」にして、入力欄がせまくならないように）
            Text(post.text)
                .font(.body)
                .foregroundStyle(.appTextPrimary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 投稿した日時（「2026年11月2日 19:49」の形）
            Text(
                post.createdAt.formatted(
                    .dateTime.year().month().day().hour().minute()
                        .locale(Locale(identifier: "ja_JP"))
                )
            )
            .font(.caption)
            .foregroundStyle(.appTextSecondary)

            Divider()
                .overlay(Color.appCardBorder)  // うすい紫の区切り線
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // 返信先の投稿（返信のときだけ）
                if let replyTo {
                    replySourceSection(replyTo)
                }

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
                                Text(replyTo == nil ? "いまどうしてる？" : "返信する")
                                    .foregroundStyle(
                                        Color.appTextSecondary.opacity(0.6)
                                    )
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                            TextEditor(text: $viewModel.text)
                                .scrollContentBackground(.hidden)  // TextEditor の白い背景を消す
                                .foregroundStyle(.appTextPrimary)
                                // 最低の高さ（返信のときは返信先の投稿があるぶん低くして、キーボードと重ならないように）
                                .frame(
                                    minHeight: replyTo == nil ? 160 : 80,
                                    maxHeight: .infinity
                                )
                                .focused($isTextFocused)
                        }
                    }
                }

                // 付けたタグ（× で外せる。多いときは横にスクロール）
                if !viewModel.selectedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.selectedTags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text("#\(tag)")
                                    Button {
                                        viewModel.removeTag(tag)

                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                }
                                .font(.footnote)
                                .foregroundStyle(.appTextSecondary)
                                .padding(.leading, 10)
                                .padding(.trailing, 6)
                                .padding(.vertical, 4)
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            Color.appCardBorder,
                                            lineWidth: 1
                                        )  // タイムラインのタグと同じ、うすい紫の枠
                                )
                            }
                        }
                        .padding(1)  // 枠線のはしが切れないように
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
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(errorMessage)
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button {
                            // エラーを消す（ふわっと消えるように、アニメーション付きで）
                            withAnimation {
                                viewModel.errorMessage = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                    }
                    .foregroundStyle(.appErrorText)  // 文字とアイコンの赤（ライト／ダークで変わる）
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.appErrorBackground)  // うすい赤の背景（ライト／ダークで変わる）
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                        .stroke(
                            Color.appErrorBorder,
                            lineWidth: 1
                        )  // うすい赤の枠（ライト／ダークで変わる）
                    )
                    .transition(.opacity)  //withAnimationが実行されたらViewがふわっと消える
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .safeAreaInset(edge: .bottom) {
                // 画面の一番下に置く（キーボードが出たら、キーボードのすぐ上に上がる）
                VStack(spacing: 0) {
                    if isShowingTagInput {
                        tagInputRow  // タグの入力欄（タグボタンを押したときだけ）
                    }
                    toolRow
                }
            }
            .navigationTitle(replyTo == nil ? "新規投稿" : "返信")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {  // 画面を開いたら実行
                viewModel.text = draftText
                isTextFocused = true  // 画面が開いたら、本文の入力欄にフォーカスを当てる（キーボードが出る）
            }
            // 入力するたびに下書きに保存する（閉じ方に関係なく、いつも最新が残る）
            .onChange(of: viewModel.text) { _, newValue in
                draftText = newValue
            }
            .toolbar {
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
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isPosting {
                            ProgressView()
                        } else {
                            Text(replyTo == nil ? "投稿" : "返信")
                        }
                    }
                    .buttonStyle(.glassProminent)  // 色付きのガラスのボタン
                    .tint(Color.accentColor)  // 色はアプリカラー（エメラルド）
                    .disabled(!viewModel.canPost)
                }
            }
            .animation(.default, value: viewModel.errorMessage)  // エラーメッセージが表示されるとふわっと現れる
            .sensoryFeedback(.error, trigger: viewModel.errorMessage) {
                _,
                newValue in
                newValue != nil
            }  // バイブレーション
        }  // NavigationStack の終わり
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

// 返信の画面（返信先の投稿を表示）
#Preview("返信") {
    ComposePostView(
        user: User(
            id: "preview",
            name: "すてぃーぶ",
            iconURL: nil,
            device: .nintendoSwitch,
            bio: nil
        ),
        replyTo: Post(
            id: "preview1",
            userId: "user1",
            replyToPostId: nil,
            text: "拠点の横に村ができてた！交易所にしたい",
            imageURLs: [],
            createdAt: Date().addingTimeInterval(-3 * 60 * 60),  // 今から3時間前
            tags: ["建築", "サバイバル"],
            replyCount: 0,
            likeCount: 5,
            userName: "たいき",
            userIconURL: nil,
            version: "1.21.40",
            device: .nintendoSwitch,
            seed: nil,
            realmsCode: nil,
            serverAddress: nil,
            xboxGamertag: nil
        ),
        onPosted: {}
    )
}
