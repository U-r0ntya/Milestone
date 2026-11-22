import SwiftUI
import UniformTypeIdentifiers

// ワールドの登録の画面（シート）
// 「Minecraft」フォルダを選ぶ → 見つかったワールドが並ぶ → 登録するものを選ぶ → 登録する
// 写真もいっしょに読みこむ（写真は端末の中だけに保存する）
struct WorldImportView: View {
    let user: User  // ログイン中の人（持ち主と機種に使う）
    let onSaved: () -> Void  // 登録できたときに、親（一覧）に知らせる
    @State private var viewModel: WorldImportViewModel
    @State private var isShowingFilePicker = false  // フォルダを選ぶ画面を出しているか
    @Environment(\.dismiss) private var dismiss  // 登録できたときに、シートを閉じるための機能

    // 今使っている端末の機種（ワールドを登録した機種として保存する。説明の文にも使う）
    private var device: Device {
        UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
    }

    // ほかの画面と同じ2つの init（MainActor の都合）
    // existingWorlds：すでに登録してあるワールド（同じワールドを2回登録しないために使う）
    init(
        user: User,
        existingWorlds: [World],
        onSaved: @escaping () -> Void
    ) {
        self.user = user
        self.onSaved = onSaved
        _viewModel = State(
            initialValue: WorldImportViewModel(existingWorlds: existingWorlds)
        )
    }

    // プレビュー用。candidates を渡すと、読みこみ成功の見た目から始まる
    init(
        user: User,
        repository: WorldRepository,
        existingWorlds: [World] = [],
        candidates: [WorldImportViewModel.Candidate] = [],
        onSaved: @escaping () -> Void
    ) {
        self.user = user
        self.onSaved = onSaved
        let viewModel = WorldImportViewModel(
            repository: repository,
            existingWorlds: existingWorlds
        )
        viewModel.candidates = candidates
        viewModel.selectedIds = Set(candidates.filter { !$0.isRegistered }.map(\.id))
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 失敗したときの文（読みこみの失敗と、登録の失敗の両方）
                    if let errorMessage = viewModel.errorMessage {
                        errorBanner(errorMessage)
                    }

                    // 読みこめたらワールドの一覧、まだなら場所の説明とボタン
                    if viewModel.candidates.isEmpty {
                        guideCard
                        pickButton
                        Text("読みこんだ情報は、ワールドの名前のほかは、あとから変えられません。写真はこの端末の中だけに保存します。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        candidateSection
                    }
                }
                .padding(16)
            }
            .background(Color.appBackground)  // 一覧と同じ、無地の背景
            // 上のバー：色を付けず、まん中にタイトル（文字はモードに合わせて黒・白）
            .navigationTitle("ワールドを登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            // フォルダを選ぶ画面（「ファイル」アプリと同じ見た目）
            .fileImporter(
                isPresented: $isShowingFilePicker,
                allowedContentTypes: [.folder]
            ) { result in
                switch result {
                case .success(let url):
                    viewModel.importMinecraftFolder(
                        from: url,
                        ownerId: user.id,
                        device: device
                    )
                case .failure:
                    viewModel.errorMessage = "フォルダを開けませんでした。もう一度試してください。"
                }
            }
            .animation(.default, value: viewModel.errorMessage)  // エラーの文をふわっと出す
        }
        .interactiveDismissDisabled(viewModel.isSaving)  // 登録中は、下にスワイプして閉じられないようにする
        // シートの上に横棒を出す（下にスワイプで閉じられる目印）。閉じられない登録中は隠す
        .presentationDragIndicator(viewModel.isSaving ? .hidden : .visible)
    }

    // 赤いエラーの文
    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle")
            Text(message)
                .font(.footnote.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.red)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))  // うすい赤の板
    }

    // Minecraft フォルダの場所の説明（3つの手順）
    private var guideCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Minecraft フォルダの場所")
                .font(.headline)

            step(1, "下のボタンを押す", "「ファイル」アプリと同じ画面が開きます")
            step(2, "「この\(device.displayName)内」を開く", "左上の「ブラウズ」から選べます")
            step(3, "「Minecraft」フォルダを選んで「開く」", "中のワールドが、写真といっしょに全部並びます")

            Divider()

            Text("並んだワールドの中から、登録したいものを選べます。登録してあるワールドは選べません。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    // 手順の1行：丸い番号・見出し・説明
    private func step(_ number: Int, _ title: String, _ detail: String)
        -> some View
    {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.footnote.bold())
                .frame(width: 24, height: 24)
                .background(Color.primary.opacity(0.08), in: Circle())  // うすい灰色の丸
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // 「Minecraft フォルダを選ぶ」ボタン
    private var pickButton: some View {
        Button {
            isShowingFilePicker = true
        } label: {
            Label("Minecraft フォルダを選ぶ", systemImage: "folder")
                .frame(maxWidth: .infinity)
                .foregroundStyle(Color(.systemBackground))  // 黒い板に白い文字（ダークは白い板に黒い文字）
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    // 読みこみ成功：見つかったワールドの一覧と、登録のボタン
    @ViewBuilder
    private var candidateSection: some View {
        HStack {
            Label("\(viewModel.candidates.count)個のワールドが見つかりました", systemImage: "checkmark.circle")
                .font(.subheadline.bold())
            Spacer(minLength: 8)
            // まだ登録していないものを、全部選ぶ・全部外す
            if viewModel.hasUnregistered {
                Button(viewModel.isAllSelected ? "全部外す" : "全部選ぶ") {
                    viewModel.toggleAll()
                }
                .font(.subheadline.bold())
                .disabled(viewModel.isSaving)
            }
        }

        VStack(spacing: 0) {
            ForEach(viewModel.candidates) { candidate in
                candidateRow(candidate)
                if candidate.id != viewModel.candidates.last?.id {
                    Divider()
                        .padding(.leading, 112)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))

        VStack(spacing: 4) {
            // 選んだワールドを登録する（登録中はぐるぐるを出して、押せなくする）
            Button {
                Task {
                    await viewModel.save()
                    // 1つでも登録できたら、親に知らせて一覧を読みなおす
                    if viewModel.savedCount > 0 {
                        onSaved()
                    }
                    // 全部登録できたら、シートを閉じる。失敗があれば閉じずにエラーを見せる
                    if viewModel.isSaved {
                        dismiss()
                    }
                }
            } label: {
                Group {
                    if viewModel.isSaving {
                        ProgressView().tint(Color(.systemBackground))
                    } else {
                        Text("選んだ \(viewModel.selectedCandidates.count) 個を登録する")
                    }
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(Color(.systemBackground))  // 黒い板に白い文字（ダークは白い板に黒い文字）
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isSaving || viewModel.selectedCandidates.isEmpty)

            // 別のフォルダを選びなおす
            Button("Minecraft フォルダを選びなおす") {
                isShowingFilePicker = true
            }
            .font(.subheadline.bold())
            .frame(height: 44)
            .disabled(viewModel.isSaving)
        }
    }

    // 見つかったワールドの1行：写真・名前・モードと日数・選んでいるか
    private func candidateRow(_ candidate: WorldImportViewModel.Candidate) -> some View {
        let isSelected = viewModel.selectedIds.contains(candidate.id)
        let world = candidate.world

        return Button {
            viewModel.toggle(candidate)
        } label: {
            HStack(spacing: 12) {
                thumbnail(candidate)

                VStack(alignment: .leading, spacing: 2) {
                    Text(world.displayName)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Text(subtitle(world))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if candidate.isRegistered {
                    Text("登録済み")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())  // 透明なところも、押せる範囲に入れる
        }
        .buttonStyle(.plain)
        .disabled(candidate.isRegistered || viewModel.isSaving)
        .opacity(candidate.isRegistered ? 0.5 : 1)  // 登録済みは、うすくして選べないことを見せる
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // 「サバイバル・120日目」のような説明
    private func subtitle(_ world: World) -> String {
        var parts = [world.gameMode.displayName]
        if let time = world.time {
            parts.append("\(time / 24000)日目")
        }
        return parts.joined(separator: "・")
    }

    // 小さい写真（16:9。写真がなければ、ゲームモードのアイコン）
    private func thumbnail(_ candidate: WorldImportViewModel.Candidate) -> some View {
        Color.clear
            .frame(width: 88, height: 49.5)
            .overlay {
                if let data = candidate.photo, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.tertiarySystemFill)
                        .overlay {
                            Image(systemName: candidate.world.gameMode.iconName)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true)
    }
}

// プレビュー用のワールド
private func previewWorld(_ name: String, folder: String, mode: GameMode, days: Int64) -> World {
    World(
        id: "preview-\(folder)",
        ownerId: "preview",
        device: .iPhone,
        createdAt: Date(),
        name: name,
        seed: 7_927_532_591_901_215_510,
        gameMode: mode,
        difficulty: .normal,
        spawnPoint: BlockPosition(x: 0, z: 0),
        lastOpenedVersion: "1.26.52",
        lastPlayed: Date().addingTimeInterval(-3 * 60 * 60),  // 3時間前
        time: 24000 * days,
        worldType: .infinite,
        commandsEnabled: false,
        hasUsedCheats: false,
        isMultiplayer: true,
        texturePacksRequired: false,
        playerPermission: .member,
        folderName: folder
    )
}

private let previewUser = User(id: "preview", name: "たいき")

// 選ぶ前
#Preview("選ぶ前") {
    WorldImportView(
        user: previewUser,
        repository: MockWorldRepository(),
        onSaved: {}
    )
}

// 読みこみ成功（1つは登録済み）
#Preview("読みこみ成功") {
    WorldImportView(
        user: previewUser,
        repository: MockWorldRepository(),
        candidates: [
            .init(world: previewWorld("はじまりの島", folder: "a", mode: .survival, days: 120), photo: nil, isRegistered: false),
            .init(world: previewWorld("建築用", folder: "b", mode: .creative, days: 12), photo: nil, isRegistered: false),
            .init(world: previewWorld("村づくりハード", folder: "c", mode: .survival, days: 45), photo: nil, isRegistered: true),
        ],
        onSaved: {}
    )
}
