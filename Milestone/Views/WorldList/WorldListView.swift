import SwiftUI

// ワールドの一覧：お気に入り → 最近遊んだワールド → 残りのワールド（どれも同じ写真のカード）
// ワールドの登録と全部の更新は、右上の ＋ と ↻ から
struct WorldListView: View {
    let user: User  // ログイン中の人
    @State private var viewModel: WorldListViewModel
    @State private var isShowingImport = false  // 登録の画面（シート）を出しているか
    @Environment(\.colorScheme) private var colorScheme  // ダークモードなら、背景を黒にする
    @State private var scrollOffset: CGFloat = 0  // 下に何ポイントスクロールしたか

    // 上のバーに「ワールド」を出すか（画面の中の大きいタイトルが、スクロールで上に隠れたら出す）
    private var showsBarTitle: Bool {
        scrollOffset > 44  // 大きいタイトルの 1 行ぶん
    }

    // ほかの画面と同じ2つの init（MainActor の都合）
    // お気に入りの最初の値は、ここで渡す（.task で入れると、タブを戻るたびに古い値で上書きされる）
    init(user: User) {
        self.user = user
        _viewModel = State(
            initialValue: WorldListViewModel(
                favoriteWorldId: user.favoriteWorldId
            )
        )
    }

    init(
        user: User,
        repository: WorldRepository,
        userRepository: UserRepository
    ) {
        self.user = user
        _viewModel = State(
            initialValue: WorldListViewModel(
                repository: repository,
                userRepository: userRepository,
                favoriteWorldId: user.favoriteWorldId
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header

                content
            }
            .padding(16)
            // 結果のカードが出たとき、お気に入りが変わったときに、並びの変化に動きをつける
            .animation(.snappy, value: viewModel.updateAllMessage)
            .animation(.snappy, value: viewModel.favoriteWorldId)
        }
        // スクロールした量を受け取る（いちばん上で 0、下にスクロールするとプラス）
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, newValue in
            scrollOffset = newValue
        }
        // 背景：ライトは見やすい白、ダークは黒（写真のカードの枠の色が引き立つように、無地にする）
        .background {
            Color(hex: colorScheme == .dark ? 0x07080C : 0xF4F5F8)
                .ignoresSafeArea()
        }
        // 上のバー：ふだんは色を付けない。スクロールして大きいタイトルが隠れたら、バーと「ワールド」を出す
        .navigationTitle("ワールド")  // 次の画面の戻るボタンに出る名前
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(
            showsBarTitle ? .visible : .hidden,
            for: .navigationBar
        )
        .animation(.easeInOut(duration: 0.2), value: showsBarTitle)
        .toolbar {
            // まん中：小さい「ワールド」（スクロールしたときだけ見える）
            ToolbarItem(placement: .principal) {
                Text("ワールド")
                    .font(.headline)
                    .opacity(showsBarTitle ? 1 : 0)
                    .accessibilityHidden(!showsBarTitle)
            }
            // 右：＋（ワールドを登録）と、全部のワールドの更新
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingImport = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("ワールドを登録")
            }

            // 全部のワールドを、level.dat を読みなおして更新する（ワールドがあるときだけ）
            if !viewModel.worlds.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.updateAllWorlds() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isUpdatingAll)  // 更新中は押せない（連打を防ぐ）
                    .accessibilityLabel("全部のワールドを更新")
                }
            }
        }
        // 「ワールドを登録」を押すと、登録の画面が下から出る
        .sheet(isPresented: $isShowingImport) {
            // 今あるワールドも渡す（同じワールドを2回登録しないため）
            WorldImportView(user: user, existingWorlds: viewModel.worlds) {
                // 登録できたら、一覧を読みこみなおす
                Task { await viewModel.loadWorlds(ownerId: user.id) }
            }
        }
        // NavigationLink で渡されたワールドを受け取って、情報の画面を出す
        .navigationDestination(for: World.self) { world in
            WorldDetailView(user: user, worldId: world.id, viewModel: viewModel)
        }
        .refreshable {
            await viewModel.loadWorlds(ownerId: user.id)  // 引っ張って更新
        }
        .task {
            await viewModel.loadWorlds(ownerId: user.id)  // 画面を開いたときに読み込む
        }
    }

    // 画面の中の大きいタイトル：「ワールド」と、その下にワールドの数
    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("ワールド")
                .font(.system(size: 34, weight: .medium))
                .accessibilityAddTraits(.isHeader)
            if !viewModel.worlds.isEmpty {
                Text("\(viewModel.worlds.count)つのワールド")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 4)
    }

    // ワールドがあるか・読み込み中か・エラーかで、出すものを切り替える
    @ViewBuilder
    private var content: some View {
        if !viewModel.worlds.isEmpty {
            worldSections
        } else if viewModel.isLoading {
            ProgressView()
                .padding(.top, 40)
        } else if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView {
                Label("読み込めませんでした", systemImage: "wifi.exclamationmark")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("もう一度読み込む") {
                    Task { await viewModel.loadWorlds(ownerId: user.id) }
                }
                .buttonStyle(.worldListGradient)
            }
        } else {
            ContentUnavailableView(
                "まだワールドがありません",
                systemImage: "cube",
                description: Text("右上の ＋ から、最初のワールドを登録してみよう")
            )
        }
    }

    // お気に入り → 最近遊んだワールド → 残り（残りには見出しを付けない）
    @ViewBuilder
    private var worldSections: some View {
        // 全体の更新の結果（× で消せる）
        if let message = viewModel.updateAllMessage {
            // 文字の 1 行目の線（ベースライン）にそろえる。アイコンも文字と同じ大きさにする
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.body.bold())
                    .foregroundStyle(Color.worldListAccent)
                Text(message)
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    withAnimation(.snappy) {
                        viewModel.updateAllMessage = nil  // カードを、動きをつけて消す
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("とじる")
            }
            .padding(12)
            .worldListGlass(cornerRadius: 16)
            // 出るとき・消えるとき：上から少し動きながら、ふわっと出入りする
            .transition(.move(edge: .top).combined(with: .opacity))
        }

        // 引っ張って更新に失敗したときは、前のワールドを残して上にエラーを出す
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.footnote.bold())
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        // カードの見た目は全部同じ。見出しだけで分ける
        if let favorite = viewModel.favoriteWorld {
            sectionHeader("お気に入り")
            card(favorite)
        }

        if let recent = viewModel.recentWorld {
            // 開いた日時で選ばれたときは「閲覧した」、遊んだ日時で選ばれたときは「遊んだ」
            sectionHeader(
                viewModel.isRecentByOpened ? "最近閲覧したワールド" : "最近遊んだワールド"
            )
            card(recent)
        }

        ForEach(viewModel.otherWorlds) { world in
            card(world)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .accessibilityAddTraits(.isHeader)
    }

    private func card(_ world: World) -> some View {
        // カードを押すと、ワールドの情報の画面に進む（星のボタンは、自分の動きを優先する）
        NavigationLink(value: world) {
            cardBody(world)
        }
        .buttonStyle(.plain)
    }

    private func cardBody(_ world: World) -> some View {
        WorldCardView(
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
    }
}

#Preview {
    NavigationStack {
        WorldListView(
            user: User(id: "preview", name: "たいき"),
            repository: MockWorldRepository(),
            userRepository: MockUserRepository()
        )
    }
}
