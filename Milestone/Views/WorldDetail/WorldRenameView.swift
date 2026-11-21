import SwiftUI

// 名前を変える画面（情報の画面から、下から出る小さな画面）
// 保存するのは、アプリでの名前（customName）。level.dat の名前は変わらない
struct WorldRenameView: View {
    let world: World
    let viewModel: WorldListViewModel
    @State private var text: String  // 入力中の名前
    @FocusState private var isFocused: Bool  // 入力欄が選ばれているか（true でキーボードが出る）
    @Environment(\.dismiss) private var dismiss

    init(world: World, viewModel: WorldListViewModel) {
        self.world = world
        self.viewModel = viewModel
        _text = State(initialValue: world.displayName)  // 最初は、今の名前を入れておく
    }

    // 前後の空白を取りのぞいた文字数
    private var trimmedCount: Int {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    // 保存してよいか（1〜30 文字で、保存中ではない）
    private var canSave: Bool {
        (1...30).contains(trimmedCount) && !viewModel.isRenaming
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                // 入力欄：カプセル型（うすい灰色で塗って、細いふちを付ける）
                TextField("ワールドの名前", text: $text)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(Color(.secondarySystemBackground), in: Capsule())
                    .overlay {
                        Capsule().strokeBorder(Color(.separator), lineWidth: 1)
                    }
                    .focused($isFocused)

                HStack {
                    if let message = viewModel.errorMessage {
                        Text(message)
                            .foregroundStyle(Color.appErrorText)
                    }
                    Spacer(minLength: 0)
                    Text("\(trimmedCount) / 30")
                        .foregroundStyle(
                            trimmedCount > 30
                                ? Color.appErrorText : Color.appTextSecondary
                        )
                }
                .font(.caption)

                Text("マイクラでの名前は「\(world.name)」です。ここで変えるのは、アプリで見える名前だけです。")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
                Spacer(minLength: 0)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        Task {
                            if await viewModel.renameWorld(
                                id: world.id,
                                to: text
                            ) {
                                dismiss()  // 保存できたら閉じる
                            }
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(!canSave)
                }
            }
            .padding(16)
            .navigationTitle("ワールド名を変える")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .presentationBackground(Color.appBackground)
        .onAppear {
            viewModel.errorMessage = nil  // 前回のエラーを消す
            isFocused = true  // 開いたらすぐ入力できるように、キーボードを出す
        }
    }
}

#Preview {
    WorldRenameView(
        world: World(
            id: "preview-world-1",
            ownerId: "preview",
            device: .iPhone,
            createdAt: Date(),
            name: "サバイバル1",
            seed: nil,
            gameMode: .survival,
            difficulty: nil,
            spawnPoint: nil,
            lastOpenedVersion: nil,
            lastPlayed: nil,
            time: nil,
            worldType: nil,
            commandsEnabled: false,
            hasUsedCheats: nil,
            isMultiplayer: true,
            texturePacksRequired: nil,
            playerPermission: nil
        ),
        viewModel: WorldListViewModel(
            repository: MockWorldRepository(),
            userRepository: MockUserRepository(),
            favoriteWorldId: nil
        )
    )
}
