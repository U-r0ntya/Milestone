import Foundation
import Observation

// ワールドの一覧の ViewModel（自分のワールドを読みこむ）
@Observable
@MainActor
final class WorldListViewModel {
    // 画面が見る値
    var worlds: [World] = []  // 自分のワールド（新しく登録した順）
    var isLoading: Bool = false  // 読みこみ中か
    var errorMessage: String?  // 読みこめなかったときの文
    var favoriteWorldId: String?  // お気に入りのワールドの ID（ログイン中の人の User から受け取り、星を押すと Firestore に保存する）
    var isSavingFavorite = false  // お気に入りを保存中か（連打を防ぐ）

    // ワールドを読み書きする係
    private let repository: WorldRepository
    // ユーザーを書きかえる係（お気に入りの保存に使う）
    private let userRepository: UserRepository

    // ほかの ViewModel と同じ2つの init（MainActor の都合）
    // favoriteWorldId：最初のお気に入り（ログイン中の人の user.favoriteWorldId）
    init(favoriteWorldId: String?) {
        self.repository = FirestoreWorldRepository()
        self.userRepository = FirestoreUserRepository()
        self.favoriteWorldId = favoriteWorldId
    }

    init(
        repository: WorldRepository,
        userRepository: UserRepository,
        favoriteWorldId: String?
    ) {
        self.repository = repository
        self.userRepository = userRepository
        self.favoriteWorldId = favoriteWorldId
    }

    // 自分のワールドを読みこむ（ownerId はログイン中の人の ID）
    func loadWorlds(ownerId: String) async {
        guard !isLoading else { return }  // 読み込み中にもう一度呼ばれたら何もしない
        isLoading = true  // 読み込みを始めた
        defer { isLoading = false }  // この関数を抜けるときに、必ず false に戻す

        errorMessage = nil
        do {
            let fetchedWorlds: [World] = try await repository.fetchWorlds(
                ownerId: ownerId
            )  // 取ってくる
            worlds = fetchedWorlds  // 成功したら入れる
        } catch {
            errorMessage = "ワールドを読み込めませんでした。通信状態を確かめて、もう一度試してください。"  //  失敗したら
        }
    }

    // 並べ方に使う日時（最後に遊んだ日時。ない（手で入力した）ときは登録した日時）
    // 6-4 で、情報の画面を開いた日時（端末に覚える）も比べるようにする
    private func playedDate(of world: World) -> Date {
        world.lastPlayed ?? world.createdAt
    }

    // お気に入りのワールド
    var favoriteWorld: World? {
        worlds.first { $0.id == favoriteWorldId }
    }

    // 最近遊んだワールド（お気に入り以外で、いちばん新しいもの）
    var recentWorld: World? {
        worlds
            .filter { $0.id != favoriteWorldId }
            .max { playedDate(of: $0) < playedDate(of: $1) }
    }

    // 残りのワールド（最近遊んだ順）
    var otherWorlds: [World] {
        worlds
            .filter { $0.id != favoriteWorldId && $0.id != recentWorld?.id }
            .sorted { playedDate(of: $0) > playedDate(of: $1) }
    }

    // 星を押したとき：お気に入りにする。もう一度押すと外す（1つだけ）
    func toggleFavorite(_ world: World) {
        favoriteWorldId = (favoriteWorldId == world.id) ? nil : world.id
    }
}
