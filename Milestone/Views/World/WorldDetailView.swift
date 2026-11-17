import SwiftUI
import UIKit
import UniformTypeIdentifiers

// ワールドの情報の画面：大看板・名前を変える・ランク・全部の情報・下のボタン
// 一覧のカードを押すと、ここに進む。レイアウトを見るための土台（ボタンはまだ動かない。シード値のコピーだけ動く）
struct WorldDetailView: View {
    let user: User  // ログイン中の人
    let worldId: String  // 表示するワールドの ID
    let viewModel: WorldListViewModel  // お気に入り・名前の変更に使う（一覧と同じものを受け取る）
    @State private var isShowingRename = false  // 名前を変える画面を出しているか
    @State private var isShowingDeleteDialog = false  // 削除の確認を出しているか
    @State private var isShowingFilePicker = false  // 「ファイル」アプリの選ぶ画面を出しているか
    @State private var didUpdate = false  // 更新できたか（「更新しました」を出す）
    @State private var showsPickFallback = false  // 「ファイルを選びなおす」を出すか（ブックマークで失敗したとき）
    @Environment(\.dismiss) private var dismiss  // 削除できたら、一覧に戻るのに使う
    @State private var didCopySeed = false  // シード値をコピーしたか（アイコンを切りかえる）

    // 表の1行
    private struct Row: Identifiable {
        let label: String
        let value: String
        var copyText: String? = nil  // 入っていれば、右にコピーのボタンを出す
        var id: String { label }
    }

    // 表の1つのまとまり（SwiftUI の Section と名前が重ならないように InfoGroup）
    private struct InfoGroup: Identifiable {
        let title: String
        let rows: [Row]
        var id: String { title }
    }

    // 入っているデータは、全部出す（Optional の項目は、値がなければ行を出さない）
    private func sections(for world: World) -> [InfoGroup] {
        // ワールド
        var worldRows: [Row] = [
            Row(label: "ゲームモード", value: world.gameMode.displayName)
        ]
        if let difficulty = world.difficulty {
            worldRows.append(Row(label: "難易度", value: difficulty.displayName))
        }
        if let time = world.time {
            worldRows.append(Row(label: "ワールドの日数", value: "\(time / 24000)日目"))
        }
        if let worldType = world.worldType {
            worldRows.append(Row(label: "ワールドの種類", value: worldType.displayName))
        }
        if let seed = world.seed {
            worldRows.append(Row(label: "シード値", value: "\(seed)", copyText: "\(seed)"))
        }
        if let spawn = world.spawnPoint {
            worldRows.append(
                Row(label: "スポーン地点", value: "\(spawn.x) / \(spawn.y) / \(spawn.z)")
            )
        }

        // 設定
        var settingRows: [Row] = [
            Row(label: "チート", value: world.commandsEnabled ? "ON" : "OFF"),
            Row(label: "マルチプレイ", value: world.isMultiplayer ? "ON" : "OFF"),
        ]
        if let used = world.hasUsedCheats {
            settingRows.append(
                Row(label: "クリエイティブ・チートの使用", value: used ? "使った" : "使っていない")
            )
        }
        if let required = world.texturePacksRequired {
            settingRows.append(
                Row(label: "リソースパックが必須か", value: required ? "必須" : "必須ではない")
            )
        }
        if let permission = world.playerPermission {
            settingRows.append(Row(label: "自分の権限", value: permission.displayName))
        }

        // 記録
        var recordRows: [Row] = []
        if let version = world.lastOpenedVersion {
            recordRows.append(Row(label: "最後に開いたバージョン", value: version))
        }
        if let lastPlayed = world.lastPlayed {
            recordRows.append(Row(label: "最後に遊んだ日時", value: dateText(lastPlayed)))
        }
        recordRows.append(Row(label: "登録した日時", value: dateText(world.createdAt)))
        recordRows.append(Row(label: "機種", value: world.device.displayName))
        recordRows.append(Row(label: "持ち主", value: user.name))
        if world.customName != nil {
            recordRows.append(Row(label: "level.dat の名前", value: world.name))
        }
        if let folderName = world.folderName {
            recordRows.append(Row(label: "フォルダ名", value: folderName))
        }

        return [
            InfoGroup(title: "ワールド", rows: worldRows),
            InfoGroup(title: "設定", rows: settingRows),
            InfoGroup(title: "記録", rows: recordRows),
        ]
    }

    // 日時を「2026年11月15日 17:40」の形にする（日本語で出すために、ロケールを指定する）
    private func dateText(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle(date: .long, time: .shortened)
                .locale(Locale(identifier: "ja_JP"))
        )
    }

    // 一覧のデータから、ID が同じワールドを探す（名前を変えると、ここも新しくなる）
    private var world: World? {
        viewModel.worlds.first { $0.id == worldId }
    }

    var body: some View {
        Group {
            if let world {
                content(world)
            } else {
                ContentUnavailableView("ワールドが見つかりません", systemImage: "cube")
            }
        }
        .appHeader("ワールドの情報")
        .onAppear {
            viewModel.errorMessage = nil  // 前の画面のエラーを消す
            viewModel.markOpened(worldId: worldId)  // このワールドを開いた日時を記録する（一覧の並びに使う）
        }
    }

    private func content(_ world: World) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // 大看板（星でお気に入りを切りかえる）
                WorldBannerView(
                    world: world,
                    isFavorite: viewModel.favoriteWorldId == world.id,
                    onToggleFavorite: {
                        Task {
                            await viewModel.toggleFavorite(
                                userId: user.id,
                                worldId: world.id
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))

                renameRow

                // ランク（サバイバルで、日数（time）があるときだけ）
                if world.gameMode == .survival, world.time != nil {
                    card {
                        WorldRankView(rank: WorldRank(world: world))
                    }
                }

                ForEach(sections(for: world)) { section in
                    sectionCard(section)
                }

                bottomButtons(world)
            }
            .padding(16)
        }
        // 名前を変える画面（下から出る）
        .sheet(isPresented: $isShowingRename) {
            WorldRenameView(world: world, viewModel: viewModel)
        }
    }

    // 「名前を変える」の行（押すと、入力の小さな画面を出す。まだ動かない）
    private var renameRow: some View {
        Button {
            isShowingRename = true
        } label: {
            HStack {
                Label("ワールド名を変える", systemImage: "pencil")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appTextPrimary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appCardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // 表の1つのまとまり（見出し＋行）
    private func sectionCard(_ section: InfoGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
                .font(.subheadline.bold())
                .foregroundStyle(Color.appTextSecondary)
                .padding(.leading, 4)

            card {
                VStack(spacing: 0) {
                    ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                        if index > 0 { Divider() }
                        rowView(row)
                    }
                }
            }
        }
    }

    // 1行：左に項目名、右に値（コピーできる項目は、いちばん右にアイコン）
    private func rowView(_ row: Row) -> some View {
        HStack(spacing: 8) {
            Text(row.label)
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
            Spacer(minLength: 8)
            Text(row.value)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.trailing)
            if let copyText = row.copyText {
                Button {
                    UIPasteboard.general.string = copyText
                    didCopySeed = true
                } label: {
                    Image(systemName: didCopySeed ? "checkmark" : "doc.on.doc")
                        .font(.footnote)
                        .foregroundStyle(Color.appTagText)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("シード値をコピー")
            }
        }
        .padding(.vertical, 10)
    }

    // 下のボタン（更新は 6-7 の続きで動かす。いまはレイアウトを見るために置いてある）
    private func bottomButtons(_ world: World) -> some View {
        VStack(spacing: 10) {
            Button {
                Task { await reloadFromBookmark() }
            } label: {
                Text(viewModel.isUpdating ? "更新中…" : "level.dat を読みなおして更新")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondary)
            .disabled(viewModel.isUpdating)

            // ブックマークで更新できなかったときは、ファイルを選びなおせるようにする
            if showsPickFallback {
                Button {
                    isShowingFilePicker = true
                } label: {
                    Text("ファイルを選びなおす")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .disabled(viewModel.isUpdating)
            }

            if didUpdate {
                Text("更新しました")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 削除に失敗したときの文
            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.appErrorText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(role: .destructive) {
                isShowingDeleteDialog = true  // すぐには消さず、確認を出す
            } label: {
                Text("このワールドを削除")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .disabled(viewModel.isDeleting)
        }
        .padding(.top, 8)
        // 「ファイル」アプリで level.dat を選ぶ（選んだら、そのファイルで更新する）
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.data]
        ) { result in
            guard case .success(let url) = result else { return }
            Task { await update(from: url) }
        }
        // 確認（「削除する」を押したときだけ、消す。まわりを押せば、とじる）
        .confirmationDialog(
            "「\(world.displayName)」を削除しますか？",
            isPresented: $isShowingDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                Task {
                    if await viewModel.deleteWorld(userId: user.id, worldId: world.id) {
                        dismiss()  // 消せたら、一覧に戻る
                    }
                }
            }
        } message: {
            Text("アプリの一覧から消えます。元には戻せません。マイクラのワールド本体は消えません。")
        }
    }

    // ブックマークから、前に選んだ level.dat を読んで更新する（ブックマークがなければ、選ぶ画面を出す）
    private func reloadFromBookmark() async {
        didUpdate = false
        showsPickFallback = false
        viewModel.errorMessage = nil
        if let url = LevelDatBookmarkStore.resolve(for: worldId) {
            await update(from: url)
        } else {
            isShowingFilePicker = true  // ブックマークがないワールドは、選んでもらう
        }
    }

    // 指定の level.dat で更新する。失敗したら、「ファイルを選びなおす」を出す
    private func update(from url: URL) async {
        didUpdate = false
        viewModel.errorMessage = nil
        let isUpdated = await viewModel.updateWorld(worldId: worldId, from: url)
        didUpdate = isUpdated
        showsPickFallback = !isUpdated
    }

    // 白いカードの枠
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appCardBorder, lineWidth: 1)
            )
    }
}

#Preview {
    // 見本のワールドを入れた ViewModel（情報の画面は、一覧のデータから ID で探して出す）
    let viewModel = WorldListViewModel(
        repository: MockWorldRepository(),
        userRepository: MockUserRepository(),
        favoriteWorldId: nil
    )
    viewModel.worlds = [
        World(
            id: "preview-world-1",
            ownerId: "preview",
            device: .iPhone,
            createdAt: Date().addingTimeInterval(-24 * 60 * 60),
            name: "サバイバル1",
            seed: -1_234_567_890_123,
            gameMode: .survival,
            difficulty: .normal,
            spawnPoint: BlockPosition(x: 0, y: 64, z: 0),
            lastOpenedVersion: "1.21.40",
            lastPlayed: Date().addingTimeInterval(-3 * 60 * 60),
            time: 240_000_000,
            worldType: .infinite,
            commandsEnabled: false,
            hasUsedCheats: false,
            isMultiplayer: true,
            texturePacksRequired: false,
            playerPermission: .member,
            folderName: "preview-folder-1"
        )
    ]
    return NavigationStack {
        WorldDetailView(
            user: User(
                id: "preview",
                name: "たいき",
                iconURL: nil,
                device: .iPhone,
                bio: nil
            ),
            worldId: "preview-world-1",
            viewModel: viewModel
        )
    }
}
