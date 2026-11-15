import SwiftUI

// ワールドの一覧：「ワールドを登録」→ お気に入り → 最近遊んだワールド → 残りのワールド
struct WorldListView: View {
    let user: User  // ログイン中の人
    @State private var viewModel: WorldListViewModel
    @State private var isShowingImport = false  // 登録の画面（シート）を出しているか

    // ワールドを登録できる機種か（level.dat を取り出せるのは、iPhone と iPad だけ）
    private var canImport: Bool {
        user.device == .iPhone || user.device == .iPad
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
                // 登録できる機種には「ワールドを登録」、できない機種には説明を出す
                if canImport {
                    registerCard
                } else {
                    unsupportedCard
                }
                content
            }
            .padding(16)
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
            WorldDetailView(user: user, world: world, viewModel: viewModel)
        }
        .refreshable {
            await viewModel.loadWorlds(ownerId: user.id)  // 引っ張って更新
        }
        .task {
            await viewModel.loadWorlds(ownerId: user.id)  // 画面を開いたときに読み込む
        }
    }

    // 「ワールドを登録」のカード（押すと、登録の画面を開く）
    private var registerCard: some View {
        Button {
            isShowingImport = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.title3.bold())
                    .foregroundStyle(Color.appTagText)
                    .frame(width: 40, height: 40)
                    .background(Color.appTagBackground, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("ワールドを登録")
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                    Text("level.dat を選んで読みこむ")
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                }
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

    // 登録できない機種に出す説明（Switch・PlayStation・Xbox・Android・Windows など）
    private var unsupportedCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "cube")
                .font(.title2)
                .foregroundStyle(Color.appTagText)
                .frame(width: 56, height: 56)
                .background(Color.appTagBackground, in: Circle())
            Text("ワールドの登録は、iPhone・iPad でマイクラを遊んでいる人だけが使えます")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
            Text(
                "あなたの機種（\(user.device.displayName)）では、ワールドのファイルを取り出せないため、登録できません。"
            )
            .font(.footnote)
            .foregroundStyle(Color.appTextSecondary)
            Divider()
            Text("投稿には、バージョン・機種・シード値を手で入力して付けられます。")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appCardBorder, lineWidth: 1)
        )
    }

    // ワールドがあるか・読み込み中か・エラーかで、出すものを切り替える
    @ViewBuilder
    private var content: some View {
        if !viewModel.worlds.isEmpty {
            worldSections
        } else if viewModel.isLoading {
            ProgressView().padding(.top, 40)
        } else if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView {
                Label("読み込めませんでした", systemImage: "wifi.exclamationmark")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("もう一度読み込む") {
                    Task { await viewModel.loadWorlds(ownerId: user.id) }
                }
                .buttonStyle(.primary)
            }
        } else if canImport {
            ContentUnavailableView(
                "まだワールドがありません",
                systemImage: "cube",
                description: Text("上の「ワールドを登録」から、最初のワールドを登録してみよう")
            )
        }
        // 登録できない機種は、上の説明のカードだけを出す
    }

    // お気に入り → 最近遊んだワールド → 残り（残りには見出しを付けない）
    @ViewBuilder
    private var worldSections: some View {
        // 引っ張って更新に失敗したときは、前のワールドを残して上にエラーを出す
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.footnote)
                .foregroundStyle(Color.appErrorText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        if let favorite = viewModel.favoriteWorld {
            sectionHeader("お気に入り", systemImage: "star.fill")
            card(favorite, startsOpen: true)
        }

        if let recent = viewModel.recentWorld {
            sectionHeader("最近遊んだワールド", systemImage: "clock")
            card(recent, startsOpen: true)
        }

        ForEach(viewModel.otherWorlds) { world in
            card(world, startsOpen: false)
        }
    }

    private func sectionHeader(_ title: String, systemImage: String)
        -> some View
    {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(Color.appTextPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }

    private func card(_ world: World, startsOpen: Bool) -> some View {
        // カードを押すと、ワールドの情報の画面に進む（星と矢印のボタンは、それぞれ自分の動きを優先する）
        NavigationLink(value: world) {
            cardBody(world, startsOpen: startsOpen)
        }
        .buttonStyle(.plain)
    }

    private func cardBody(_ world: World, startsOpen: Bool) -> some View {
        WorldCardView(
            world: world,
            ownerName: user.name,
            isFavorite: viewModel.favoriteWorldId == world.id,
            startsOpen: startsOpen,
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
            user: User(
                id: "preview",
                name: "たいき",
                iconURL: nil,
                device: .nintendoSwitch,
                bio: nil
            ),
            repository: MockWorldRepository(),
            userRepository: MockUserRepository()
        )
        .appHeader("ワールド")
    }
}
