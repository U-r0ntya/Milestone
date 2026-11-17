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
    var isRenaming = false  // 名前を保存中か（連打を防ぐ）
    var isDeleting = false  // ワールド削除中か
    var isUpdating = false  // ワールド更新中か

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

    // 並べ方に使う日時（最後に遊んだ日時。level.dat に入っていなかったときは登録した日時）
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
    // 先に星を切りかえて見せてから Firestore に保存し、失敗したら元に戻す（いいねと同じ）
    func toggleFavorite(userId: String, worldId: String) async {
        guard !isSavingFavorite else { return }  // 保存中にもう一度押されたら何もしない
        isSavingFavorite = true  // 保存を始めた
        defer { isSavingFavorite = false }  // この関数を抜けるときに、必ず false に戻す

        let oldFavoriteWorldId = favoriteWorldId  // 押す前のお気に入り（失敗したら戻す）

        // 押したあとのお気に入り：同じワールドなら外す（nil）、違えばそのワールド
        let newFavoriteWorldId: String? =
            (favoriteWorldId == worldId) ? nil : worldId
        favoriteWorldId = newFavoriteWorldId  // 先に画面の星を切りかえる

        errorMessage = nil
        do {
            // Firestore に保存する（nil なら、お気に入りの項目を消す）
            try await userRepository.updateFavoriteWorld(
                userId: userId,
                worldId: favoriteWorldId
            )
        } catch {
            favoriteWorldId = oldFavoriteWorldId  // 失敗したら、押す前に戻す
            errorMessage = "お気に入りを保存できませんでした。通信状態を確かめて、もう一度試してください。"
        }
    }

    // 名前を変える（アプリでの名前 customName に保存する）。成功したら true
    func renameWorld(id: String, to newName: String) async -> Bool {
        guard !isRenaming else { return false }  // 保存中にもう一度呼ばれたら何もしない
        isRenaming = true  // 保存を始めた
        defer { isRenaming = false }  // この関数を抜けるときに、必ず false に戻す

        errorMessage = nil
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)  // 前後の空白を取りのぞく
        guard !trimmed.isEmpty, trimmed.count <= 30 else {
            errorMessage = "名前は、1〜30 文字で入力してください。"
            return false
        }
        guard let index = worlds.firstIndex(where: { $0.id == id }) else {
            return false  // 一覧にないワールドは、書きかえられない
        }

        do {
            try await repository.updateCustomName(id: id, customName: trimmed)
            worlds[index].customName = trimmed  // 保存できたら、画面のデータも書きかえる
            return true
        } catch {
            errorMessage = "名前を保存できませんでした。通信状態を確かめて、もう一度試してください。"
            return false
        }
    }
    // ワールドを消す処理
    // userId: 消す人、worldId: 消したいワールド
    func deleteWorld(userId: String, worldId: String) async -> Bool {
        guard !isDeleting else { return false }  // 保存中にもう一度呼ばれたら何もしない
        isDeleting = true  // 保存を始めた
        defer { isDeleting = false }  // この関数を抜けるときに、必ず false に戻す
        errorMessage = nil

        do {
            try await repository.deleteWorld(id: worldId)
            worlds.removeAll { $0.id == worldId }
            LevelDatBookmarkStore.remove(for: worldId)
            // もし消したいワールドがお気に入りなら
            if favoriteWorldId == worldId {
                try? await userRepository.updateFavoriteWorld(
                    userId: userId,
                    worldId: nil
                )
                favoriteWorldId = nil  // お気に入りを画面から消す
            }
            return true
        } catch {
            errorMessage = "ワールドが削除できませんでした。通信状態を確かめて、もう一度試してください。"
            return false
        }
    }

    // ワールドを更新する処理（選んだ level.dat を読みなおして、今のワールドを新しい内容にする）
    func updateWorld(worldId: String, from url: URL) async -> Bool {
        guard !isUpdating else { return false }
        isUpdating = true
        defer { isUpdating = false }
        errorMessage = nil

        // 一覧から、更新するワールドの場所を探す
        guard let index = worlds.firstIndex(where: { $0.id == worldId }) else {
            errorMessage = "ワールドが見つかりませんでした。"
            return false
        }
        // 更新前のワールド（id や名前など、残すものを取り出すのに使う）
        let oldWorld = worlds[index]

        // level.dat 以外のファイル（level.dat_old など）は断る
        guard url.lastPathComponent == "level.dat" else {
            errorMessage = "このファイルを読みこめませんでした。level.dat を選んでいるか、確かめてください。"
            return false
        }
        // ファイルを読む許可を取る
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "このファイルを読みこめませんでした。level.dat を選んでいるか、確かめてください。"
            return false
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // Data にする → NBTReader で辞書にする → LevelDatParser で新しい World を作る
        var newWorld: World
        do {
            let data = try Data(contentsOf: url)
            let root = try NBTReader.readLevelDat(data)
            newWorld = try LevelDatParser.parse(
                root,
                ownerId: oldWorld.ownerId,
                device: oldWorld.device
            )
        } catch {
            errorMessage = "このファイルを読みこめませんでした。level.dat を選んでいるか、確かめてください。"
            return false
        }

        // 選んだファイルのフォルダ名が、今のワールドと違えば、別のワールドなので断る
        // 今のワールドにフォルダ名がないときは、比べられないので、そのまま進む
        let folderName = url.deletingLastPathComponent().lastPathComponent
        if let oldFolderName = oldWorld.folderName,
            oldFolderName != folderName
        {
            errorMessage = "別のワールドの level.dat です。"
            return false
        }

        // parse が新しく作った値を、今のワールドのものに戻す
        newWorld.id = oldWorld.id
        newWorld.createdAt = oldWorld.createdAt
        newWorld.customName = oldWorld.customName
        newWorld.folderName = folderName

        // Firestore に保存する
        do { try await repository.saveWorld(newWorld) } catch {
            errorMessage = "ワールドを更新できませんでした。通信状態を確かめて、もう一度試してください。"
            return false
        }

        // 許可が生きているうちに、ブックマークも保存しなおす
        LevelDatBookmarkStore.save(url, for: newWorld.id)

        // 通信を待っているあいだに一覧が変わったかもしれないので、場所を探しなおす
        guard let newIndex = worlds.firstIndex(where: { $0.id == newWorld.id })
        else {
            return true  // 一覧からもう消えている → 保存はできているので、成功
        }
        worlds[newIndex] = newWorld  // 画面のデータも、新しい内容に入れかえる
        return true
    }
}
