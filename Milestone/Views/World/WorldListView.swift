import SwiftUI

// ワールドの一覧：「ワールドを登録」→ お気に入り → 最近遊んだワールド → 残りのワールド
struct WorldListView: View {
    let user: User  // ログイン中の人
    @State private var viewModel: WorldListViewModel

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
                registerCard
                content
            }
            .padding(16)
        }
        .refreshable {
            await viewModel.loadWorlds(ownerId: user.id)  // 引っ張って更新
        }
        .task {
            await viewModel.loadWorlds(ownerId: user.id)  // 画面を開いたときに読み込む
        }
    }

    // 「ワールドを登録」のカード（登録の画面は 6-5 で作る）
    private var registerCard: some View {
        Button {
            // 6-5 で、登録の画面を開く
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
                    Text("level.dat を読みこむ、または手で入力")
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
        } else {
            ContentUnavailableView(
                "まだワールドがありません",
                systemImage: "cube",
                description: Text("上の「ワールドを登録」から、最初のワールドを登録してみよう")
            )
        }
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
        WorldCardView(
            world: world,
            ownerName: user.name,
            isFavorite: viewModel.favoriteWorldId == world.id,
            startsOpen: startsOpen,
            onToggleFavorite: { viewModel.toggleFavorite(world) }
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
