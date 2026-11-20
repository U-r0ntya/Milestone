import SwiftUI
import UIKit
import UniformTypeIdentifiers

// ワールドの情報の画面（天気アプリ風）
// 背景：ブロックでできた空と地面の下（スクロールに合わせて動く。昼・夜はダークモードで切りかわる）
// 上から：ワールド名と日数 → ランク → マップ → 2 列のタイル → シード値 → ルール → くわしい情報 → ボタン
// 一覧のカードを押すと、ここに進む
struct WorldDetailView: View {
    let user: User  // ログイン中の人
    let worldId: String  // 表示するワールドの ID
    let viewModel: WorldListViewModel  // お気に入り・名前の変更・更新・削除に使う（一覧と同じものを受け取る）
    @State private var isShowingRename = false  // 名前を変える画面を出しているか
    @State private var isShowingDeleteDialog = false  // 削除の確認を出しているか
    @State private var isShowingFilePicker = false  // 「ファイル」アプリの選ぶ画面を出しているか
    @State private var didUpdate = false  // 更新できたか（「更新しました」を出す）
    @State private var showsPickFallback = false  // 「Minecraft フォルダを選ぶ」を出すか（覚えた場所で失敗したとき）
    @State private var didCopySeed = false  // シード値をコピーしたか（アイコンを切りかえる）
    @State private var scrollOffset: CGFloat = 0  // 下に何ポイントスクロールしたか（背景を動かすのに使う）
    @Environment(\.dismiss) private var dismiss  // 削除できたら、一覧に戻るのに使う
    @Environment(\.colorScheme) private var colorScheme  // ダークモードなら、背景を夜にする

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
                    .appHeader("ワールドの情報")
            }
        }
        .onAppear {
            viewModel.errorMessage = nil  // 前の画面のエラーを消す
            viewModel.markOpened(worldId: worldId)  // このワールドを開いた日時を記録する（一覧の並びに使う）
        }
    }

    // 上のバーにワールド名を出すか（タイトルのワールド名が、スクロールで上に隠れたら出す）
    private var showsBarTitle: Bool {
        scrollOffset > 48  // タイトルの上の余白（8）＋ ワールド名の 1 行（約 40）
    }

    // ランク（サバイバルで、日数（time）があるときだけ）
    private func rank(for world: World) -> WorldRank? {
        guard world.gameMode == .survival, world.time != nil else { return nil }
        return WorldRank(world: world)
    }

    private func content(_ world: World) -> some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 390  // デザイン（幅 390）の 1 が、画面の何ポイントか
            // 地面の下（デザインの y = 460）が、スクロールの中のどこにあるか。カードはそこから始める
            let groundY = 460 * scale - proxy.safeAreaInsets.top

            ScrollView {
                VStack(spacing: 12) {
                    WorldDetailHeader(world: world, rank: rank(for: world))
                        .padding(.top, 8)
                        .frame(minHeight: max(groundY - 12, 0), alignment: .top)

                    if let rank = rank(for: world) {
                        WorldRankCard(rank: rank)
                    }

                    WorldMapCard(days: world.days)

                    tiles(world)

                    if let seed = world.seed {
                        seedCard(seed)
                    }

                    rulesCard(world)

                    detailsCard(world)

                    bottomButtons(world)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            // スクロールした量を受け取る（いちばん上で 0、下にスクロールするとプラス）
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, newValue in
                scrollOffset = newValue
            }
            .background {
                WorldDetailBackground(
                    palette: colorScheme == .dark ? .night : .day,
                    scrollOffset: scrollOffset
                )
                .ignoresSafeArea()
            }
        }
        // カードの見出しを上にくっつけるときの基準（バーの下が y = 0）
        .coordinateSpace(.worldDetail)
        // 上のバー：戻るボタン（いつもの）と、お気に入り・更新のボタン
        // ふだんはバーの色を付けず、スクロールしてワールド名が見えなくなったら、バーとワールド名を出す
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(showsBarTitle ? .visible : .hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: showsBarTitle)
        .toolbar {
            ToolbarItem(placement: .principal) {
                // ワールド名と、その下にランク（ランクがあるときだけ）
                VStack(spacing: 0) {
                    Text(world.displayName)
                        .font(.headline)
                    if let rank = rank(for: world) {
                        Text(rank.title)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .foregroundStyle(.white)
                .lineLimit(1)
                .opacity(showsBarTitle ? 1 : 0)
                .accessibilityElement(children: .combine)
                .accessibilityHidden(!showsBarTitle)
            }
            ToolbarItem(placement: .topBarTrailing) {
                favoriteButton(world)
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await reloadFromBookmark() }
                } label: {
                    if viewModel.isUpdating {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isUpdating)
                .accessibilityLabel("Minecraft フォルダから更新する")
            }
        }
        // 名前を変える画面（下から出る）
        .sheet(isPresented: $isShowingRename) {
            WorldRenameView(world: world, viewModel: viewModel)
        }
        // 「ファイル」アプリで Minecraft フォルダを選ぶ（ワールドのフォルダ・level.dat でもよい。フォルダなら写真も新しくなる）
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.folder, .data]
        ) { result in
            guard case .success(let url) = result else { return }
            Task { await update(from: url) }
        }
    }

    // お気に入りの星（押すと切りかえる）
    private func favoriteButton(_ world: World) -> some View {
        let isFavorite = viewModel.favoriteWorldId == world.id
        return Button {
            Task {
                await viewModel.toggleFavorite(userId: user.id, worldId: world.id)
            }
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
        }
        .accessibilityLabel(isFavorite ? "お気に入りから外す" : "お気に入りにする")
    }

    // MARK: - 2 列のタイル

    private func tiles(_ world: World) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            // ゲームモード（サバイバルは「〇〇日目を突破」）
            WorldInfoTile(
                title: "ゲームモード",
                systemImage: "gamecontroller",
                value: world.gameMode.displayName,
                note: world.gameMode == .survival
                    ? world.passedMilestone.map { "\($0)日目を突破" } : nil
            )

            // 難易度（敵の攻撃力の目安。ピースフルは、モンスターが出ないこと）
            if let difficulty = world.difficulty {
                WorldInfoTile(
                    title: "難易度",
                    systemImage: "chart.bar",
                    value: difficulty.displayName,
                    emphasis: difficulty.zombieDamageText,
                    note: difficulty.attackRatioText,
                    noteSize: 12
                )
            }

            // 最後に遊んだ（何時間前か。下に登録した日）
            if let lastPlayed = world.lastPlayed {
                WorldInfoTile(
                    title: "最後に遊んだ",
                    systemImage: "clock",
                    value: lastPlayed.formatted(
                        .relative(presentation: .named).locale(Locale(identifier: "ja_JP"))
                    ),
                    note: "最終登録:\(dayText(world.createdAt))"
                )
            }

            // スポーン地点（X・Z を 1 行ずつ）
            if let spawn = world.spawnPoint {
                WorldInfoTile(
                    title: "スポーン地点",
                    systemImage: "mappin.and.ellipse",
                    value: "X \(spawn.x)\nZ \(spawn.z)",
                    valueSize: 26,  // ほかのタイルの値と同じ大きさ
                    note: spawn.directionFromOrigin
                )
            }
        }
    }

    // MARK: - シード値・ルール・くわしい情報

    // シード値（右のボタンでコピーできる）
    private func seedCard(_ seed: Int64) -> some View {
        WorldStickyCard(
            title: "シード値",
            contentPadding: EdgeInsets(top: 0, leading: 16, bottom: 14, trailing: 16)
        ) {
            seedRow(seed)
        }
    }

    // シード値の数字と、コピーのボタン
    private func seedRow(_ seed: Int64) -> some View {
        HStack(spacing: 12) {
            Text("\(seed)")
                .font(.system(size: 20, weight: .medium))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                UIPasteboard.general.string = "\(seed)"
                didCopySeed = true
            } label: {
                Image(systemName: didCopySeed ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.18), in: Circle())
                    .overlay { Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(didCopySeed ? "コピーしました" : "シード値をコピー")
        }
    }

    // ルール（ON / OFF）
    private func rulesCard(_ world: World) -> some View {
        var rules: [(label: String, isOn: Bool)] = [
            ("チート", world.commandsEnabled),
            ("マルチプレイ", world.isMultiplayer),
        ]
        if let required = world.texturePacksRequired {
            rules.append(("リソースパックが必須", required))
        }
        if let used = world.hasUsedCheats {
            rules.append(("クリエイティブ・チートの使用", used))
        }

        return listCard(title: "ルール") {
            ForEach(Array(rules.enumerated()), id: \.element.label) { index, rule in
                HStack {
                    Text(rule.label)
                        .font(.system(size: 15))
                    Spacer(minLength: 8)
                    Text(rule.isOn ? "ON" : "OFF")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(rule.isOn ? Color(hex: 0x05382A) : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 3)
                        .background(
                            rule.isOn ? Color(hex: 0x5DCAA5, opacity: 0.9) : .white.opacity(0.22),
                            in: Capsule()
                        )
                }
                .padding(.vertical, 12)
                .overlay(alignment: .top) { if index > 0 { line } }
                .accessibilityElement(children: .combine)
            }
        }
    }

    // くわしい情報（level.dat から取れた項目だけ出す）
    private func detailsCard(_ world: World) -> some View {
        var rows: [(label: String, value: String)] = []
        if let version = world.lastOpenedVersion {
            rows.append(("バージョン", version))
        }
        if let worldType = world.worldType {
            rows.append(("ワールドの種類", worldType.displayName))
        }
        rows.append(("登録日時", dateTimeText(world.createdAt)))
        rows.append(("機種", world.device.displayName))
        rows.append(("持ち主", user.name))
        if let permission = world.playerPermission {
            rows.append(("自分の権限", permission.displayName))
        }
        if let folderName = world.folderName {
            rows.append(("フォルダ名", folderName))
        }
        if world.customName != nil {
            rows.append(("level.dat の名前", world.name))
        }

        return listCard(title: "くわしい情報") {
            ForEach(Array(rows.enumerated()), id: \.element.label) { index, row in
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text(row.label)
                        .foregroundStyle(.white.opacity(0.75))
                        .fixedSize()
                    Spacer(minLength: 0)
                    Text(row.value)
                        .multilineTextAlignment(.trailing)
                }
                .font(.system(size: 14))
                .padding(.vertical, 12)
                .overlay(alignment: .top) { if index > 0 { line } }
                .accessibilityElement(children: .combine)
            }
        }
    }

    // 見出しと、線で区切った行のカード（見出しは上にくっつく）
    private func listCard<Rows: View>(title: String, @ViewBuilder rows: () -> Rows) -> some View {
        WorldStickyCard(
            title: title,
            contentPadding: EdgeInsets(top: 0, leading: 16, bottom: 6, trailing: 16)
        ) {
            VStack(alignment: .leading, spacing: 0) {
                rows()
            }
        }
    }

    // 行と行のあいだの線
    private var line: some View {
        Rectangle()
            .fill(.white.opacity(0.18))
            .frame(height: 1)
    }

    // MARK: - 下のボタン

    // 名前を変える・Minecraft フォルダから更新する（覚えた場所で読み、だめなら選びなおす）・ワールドの削除
    private func bottomButtons(_ world: World) -> some View {
        VStack(spacing: 10) {
            Button("名前を変える") {
                isShowingRename = true
            }
            .buttonStyle(.worldGlass)

            Button(viewModel.isUpdating ? "更新中…" : "Minecraft フォルダから更新する") {
                Task { await reloadFromBookmark() }
            }
            .buttonStyle(.worldGlass)
            .disabled(viewModel.isUpdating)

            // 覚えた場所で更新できなかったときは、選びなおせるようにする
            if showsPickFallback {
                Button("Minecraft フォルダを選ぶ") {
                    isShowingFilePicker = true
                }
                .buttonStyle(.worldGlass)
                .disabled(viewModel.isUpdating)
            }

            if didUpdate {
                statusText("更新しました", color: .white)
            }

            // 更新・削除に失敗したときの文
            if let message = viewModel.errorMessage {
                statusText(message, color: Color(hex: 0xFFD9D5))
            }

            Button("このワールドを削除") {
                isShowingDeleteDialog = true  // すぐには消さず、確認を出す
            }
            .buttonStyle(.worldGlassDestructive)
            .disabled(viewModel.isDeleting)
            // 確認（ボタンの近くに出る。「削除する」を押したときだけ消す。まわりを押せば、とじる）
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
        .padding(.top, 4)
    }

    // ボタンの近くに出す、短いお知らせの文（暗い背景で読めるように、うすい影を付ける）
    private func statusText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(color)
            .shadow(color: .black.opacity(0.4), radius: 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    // MARK: - 日時の形

    // 「2026/11/07」の形
    private func dayText(_ date: Date) -> String {
        date.formatted(
            .verbatim(
                "\(year: .defaultDigits)/\(month: .twoDigits)/\(day: .twoDigits)",
                timeZone: .current,
                calendar: Calendar(identifier: .gregorian)
            )
        )
    }

    // 「2026/11/07 12:58」の形
    private func dateTimeText(_ date: Date) -> String {
        date.formatted(
            .verbatim(
                "\(year: .defaultDigits)/\(month: .twoDigits)/\(day: .twoDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)",
                timeZone: .current,
                calendar: Calendar(identifier: .gregorian)
            )
        )
    }

    // MARK: - 更新

    // 覚えた Minecraft フォルダ（なければ、このワールドで前に選んだ場所）から読んで更新する
    // どちらもなければ、選ぶ画面を出す
    private func reloadFromBookmark() async {
        didUpdate = false
        showsPickFallback = false
        viewModel.errorMessage = nil
        let minecraftFolder = world?.folderName != nil ? MinecraftFolderStore.resolve() : nil
        if let url = minecraftFolder ?? LevelDatBookmarkStore.resolve(for: worldId) {
            await update(from: url)
        } else {
            isShowingFilePicker = true  // 覚えた場所がないワールドは、選んでもらう
        }
    }

    // 指定の場所で更新する。失敗したら、「Minecraft フォルダを選ぶ」を出す
    private func update(from url: URL) async {
        didUpdate = false
        viewModel.errorMessage = nil
        let isUpdated = await viewModel.updateWorld(worldId: worldId, from: url)
        didUpdate = isUpdated
        showsPickFallback = !isUpdated
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
            spawnPoint: BlockPosition(x: 128, z: -64),
            lastOpenedVersion: "1.21.40",
            lastPlayed: Date().addingTimeInterval(-3 * 60 * 60),
            time: 120 * 24000,  // 120 日目
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
