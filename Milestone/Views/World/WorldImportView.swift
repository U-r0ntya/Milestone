import SwiftUI
import UniformTypeIdentifiers

// ワールドの登録の画面（シート）
// level.dat を選ぶ → 読みこんだ内容を確かめる → 登録する
struct WorldImportView: View {
    let user: User  // ログイン中の人（持ち主と機種に使う）
    let onSaved: () -> Void  // 登録できたときに、親（一覧）に知らせる
    @State private var viewModel: WorldImportViewModel
    @State private var isShowingFilePicker = false  // ファイルを選ぶ画面を出しているか
    @Environment(\.dismiss) private var dismiss  // 登録できたときに、シートを閉じるための機能
    @Environment(\.colorScheme) private var colorScheme  // ダークモードなら、背景を夜の星空にする

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

    // プレビュー用。world を渡すと、読みこみ成功の見た目から始まる
    init(
        user: User,
        repository: WorldRepository,
        existingWorlds: [World] = [],
        world: World? = nil,
        onSaved: @escaping () -> Void
    ) {
        self.user = user
        self.onSaved = onSaved
        let viewModel = WorldImportViewModel(
            repository: repository,
            existingWorlds: existingWorlds
        )
        viewModel.world = world
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
                    // すでに登録してあるワールドを選んだときの文
                    if viewModel.isDuplicate {
                        errorBanner("このワールドは、すでに登録してあります。別のワールドの level.dat を選んでください。")
                    }

                    // 読みこめたら内容の確認、まだなら場所の説明とボタン
                    if let world = viewModel.world {
                        confirmSection(world)
                    } else {
                        guideCard
                        pickButton
                        Text("読みこんだ情報は、ワールドの名前のほかは、あとから変えられません。")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
            }
            // 背景：一覧と同じ空（昼は青い空と雲、夜は星空）
            .background {
                WorldListBackground(isNight: colorScheme == .dark, showsSunAndMoon: false)
                    .ignoresSafeArea()
            }
            // 上のバー：色を付けず空を見せて、まん中に白いタイトル
            .navigationTitle("ワールドを登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ワールドを登録")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            // ファイルを選ぶ画面（「ファイル」アプリと同じ見た目）
            .fileImporter(
                isPresented: $isShowingFilePicker,
                allowedContentTypes: [.data]
            ) { result in
                switch result {
                case .success(let url):
                    // 選んだファイルを読みこむ
                    viewModel.importLevelDat(
                        from: url,
                        ownerId: user.id,
                        device: user.device
                    )
                case .failure:
                    viewModel.errorMessage = "ファイルを開けませんでした。もう一度試してください。"
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
        .foregroundStyle(Color(hex: 0xFFD9D5))  // 空の上でも読める、うすい赤
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        // 赤みのあるガラス（詳細画面の「削除」のボタンと同じ色）
        .background(Color(hex: 0xB3261E, opacity: 0.35), in: RoundedRectangle(cornerRadius: 16))
        .worldListGlass(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(hex: 0xFF786E, opacity: 0.55), lineWidth: 1)
        )
    }

    // level.dat の場所の説明（3つの手順）
    private var guideCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("level.dat の場所")
                .font(.headline)
                .foregroundStyle(.white)

            step(1, "「ファイル」アプリを開く", "この\(user.device.displayName)内 → Minecraft")
            step(
                2,
                "ワールドのフォルダまで進む",
                "games → com.mojang → minecraftWorlds → ワールドのフォルダ"
            )
            step(3, "level.dat を選ぶ", "「level.dat_old」ではなく、「level.dat」のほう")

            Rectangle()
                .fill(.white.opacity(0.14))
                .frame(height: 1)

            Text("ワールドのフォルダは、記号がならんだ名前です。中の levelname.txt を開くと、ワールドの名前を確かめられます。")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .worldListGlass(cornerRadius: 20)
    }

    // 手順の1行：丸い番号・見出し・説明
    private func step(_ number: Int, _ title: String, _ detail: String)
        -> some View
    {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.footnote.bold())
                .foregroundStyle(Color.worldListAccent)
                .worldListGlassCircle(size: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
    }

    // 「ファイルを選ぶ」ボタン（失敗のあとも、同じ文のまま。文を変えるとレイアウトが動くため）
    private var pickButton: some View {
        Button {
            isShowingFilePicker = true
        } label: {
            Label("ファイルを選ぶ", systemImage: "folder")
        }
        .buttonStyle(.worldListGradient)
    }

    // 読みこみ成功：内容の確認と、登録のボタン
    @ViewBuilder
    private func confirmSection(_ world: World) -> some View {
        Label("読みこめました。内容を確かめてください", systemImage: "checkmark.circle")
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.3), radius: 4, y: 1)  // 明るい空の上でも読めるように
            .frame(maxWidth: .infinity, alignment: .leading)

        // 一覧と同じすりガラスの看板（星と開閉ボタンはなし。最初から全部見せる）
        VStack(spacing: 0) {
            WorldBannerView(
                world: world,
                isFavorite: false,
                onToggleFavorite: {},
                showsFavorite: false,
                isGlass: true
            )
            WorldSubBannerView(world: world, ownerName: user.name, isGlass: true)
                .padding(.bottom, 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .worldListGlass(cornerRadius: 20)
        // すでに登録してあるときは、カードをうすくして、登録できないことを見せる
        .opacity(viewModel.isDuplicate ? 0.45 : 1)

        VStack(spacing: 4) {
            // 登録する（登録中はぐるぐるを出して、押せなくする。すでに登録してあるときも押せない）
            Button {
                Task {
                    await viewModel.save()
                    // 登録できたら、親に知らせてシートを閉じる。失敗したら閉じずにエラーを見せる
                    if viewModel.isSaved {
                        onSaved()
                        dismiss()
                    }
                }
            } label: {
                Group {
                    if viewModel.isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("この内容で登録する")
                    }
                }
            }
            .buttonStyle(.worldListGradient)
            .disabled(viewModel.isSaving || viewModel.isDuplicate)

            // 別のファイルを選びなおす
            Button("ファイルを選びなおす") {
                isShowingFilePicker = true
            }
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .frame(height: 44)
            .disabled(viewModel.isSaving)
        }
    }
}

// 選ぶ前
#Preview("選ぶ前") {
    WorldImportView(
        user: User(
            id: "preview",
            name: "たいき",
            iconURL: nil,
            device: .iPhone,
            bio: nil
        ),
        repository: MockWorldRepository(),
        onSaved: {}
    )
}

// 読みこみ成功
#Preview("読みこみ成功") {
    WorldImportView(
        user: User(
            id: "preview",
            name: "たいき",
            iconURL: nil,
            device: .iPhone,
            bio: nil
        ),
        repository: MockWorldRepository(),
        world: World(
            id: "preview-world",
            ownerId: "preview",
            device: .iPhone,
            createdAt: Date(),
            name: "はじまりの島",
            seed: 7_927_532_591_901_215_510,
            gameMode: .survival,
            difficulty: .normal,
            spawnPoint: BlockPosition(x: 0, z: 0),
            lastOpenedVersion: "1.26.52",
            lastPlayed: Date().addingTimeInterval(-3 * 60 * 60),  // 3時間前
            time: 24000 * 120,  // 120日
            worldType: .infinite,
            commandsEnabled: false,
            hasUsedCheats: false,
            isMultiplayer: true,
            texturePacksRequired: false,
            playerPermission: .member
        ),
        onSaved: {}
    )
}

// すでに登録してあるワールドを選んだとき
#Preview("登録済み") {
    // 同じフォルダ名のワールドを、「登録してあるワールド」と「読みこんだワールド」の両方に渡す
    let world = World(
        id: "preview-world",
        ownerId: "preview",
        device: .iPhone,
        createdAt: Date(),
        name: "はじまりの島",
        seed: 7_927_532_591_901_215_510,
        gameMode: .survival,
        difficulty: .normal,
        spawnPoint: BlockPosition(x: 0, z: 0),
        lastOpenedVersion: "1.26.52",
        lastPlayed: Date().addingTimeInterval(-3 * 60 * 60),  // 3時間前
        time: 24000 * 120,  // 120日
        worldType: .infinite,
        commandsEnabled: false,
        hasUsedCheats: false,
        isMultiplayer: true,
        texturePacksRequired: false,
        playerPermission: .member,
        folderName: "preview-folder"
    )
    return WorldImportView(
        user: User(
            id: "preview",
            name: "たいき",
            iconURL: nil,
            device: .iPhone,
            bio: nil
        ),
        repository: MockWorldRepository(),
        existingWorlds: [world],
        world: world,
        onSaved: {}
    )
}
