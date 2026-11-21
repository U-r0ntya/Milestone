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
    var isUpdatingAll = false  // 全体の更新中か
    var updateAllMessage: String?  // 結果の文
    var openedDates: [String: Date] = [:]  // ワールドの情報の画面を開いた日時（ワールドの ID → 日時。端末の中だけに保存）

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
        openedDates = WorldOpenedStore.all()
    }

    init(
        repository: WorldRepository,
        userRepository: UserRepository,
        favoriteWorldId: String?
    ) {
        self.repository = repository
        self.userRepository = userRepository
        self.favoriteWorldId = favoriteWorldId
        openedDates = WorldOpenedStore.all()
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

    // 並べ方に使う日時：「マイクラで遊んだ日時」と「アプリで開いた日時」の、新しいほう
    private func playedDate(of world: World) -> Date {
        max(
            // マイクラで最後に遊んだ日時（level.dat に入っていなかったときは、登録した日時）
            world.lastPlayed ?? world.createdAt,
            // アプリで最後に開いた日時（まだ開いていなければ、一番古い日時にして、負けるようにする）
            openedDates[world.id] ?? .distantPast
        )
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

    // 最近のワールドが、「アプリで開いた日時」で選ばれたか（true なら「最近閲覧した」、false なら「最近遊んだ」）
    var isRecentByOpened: Bool {
        // 最近のワールドと、その開いた日時がなければ（まだ開いていなければ）、遊んだほう
        guard let recent = recentWorld, let opened = openedDates[recent.id]
        else {
            return false
        }
        // 開いた日時が、マイクラで遊んだ日時より新しいときだけ true
        return opened > (recent.lastPlayed ?? recent.createdAt)
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
            WorldPhotoStore.shared.remove(for: worldId)  // 端末の中の写真も消す
            // もし消したいワールドがお気に入りなら
            if favoriteWorldId == worldId {
                try? await userRepository.updateFavoriteWorld(
                    userId: userId,
                    worldId: nil
                )
                favoriteWorldId = nil  // お気に入りを画面から消す
            }
            openedDates.removeValue(forKey: worldId)
            WorldOpenedStore.remove(for: worldId)
            return true
        } catch {
            errorMessage = "ワールドが削除できませんでした。通信状態を確かめて、もう一度試してください。"
            return false
        }
    }

    // ワールドを更新する処理（Minecraft フォルダ・ワールドのフォルダ・level.dat のどれかを読みなおして、今のワールドを新しい内容にする）
    // Minecraft フォルダのときは、今のワールドと同じフォルダ名のワールドを中から探す
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

        // フォルダなら level.dat と写真、level.dat なら level.dat だけを読み出す
        // Data → NBTReader で辞書にする → LevelDatParser で新しい World を作る
        let result: WorldFolderReader.Result
        var newWorld: World
        do {
            result = try WorldFolderReader.read(from: url, worldFolderName: oldWorld.folderName)
            let root = try NBTReader.readLevelDat(result.levelDat)
            newWorld = try LevelDatParser.parse(
                root,
                ownerId: oldWorld.ownerId,
                device: oldWorld.device
            )
        } catch {
            errorMessage = "読みこめませんでした。ワールドのフォルダか level.dat を選んでいるか、確かめてください。"
            return false
        }

        // 選んだもののフォルダ名が、今のワールドと違えば、別のワールドなので断る
        // 今のワールドにフォルダ名がないときは、比べられないので、そのまま進む
        let folderName = result.folderName
        if let oldFolderName = oldWorld.folderName,
            oldFolderName != folderName
        {
            errorMessage = "別のワールドです。"
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

        // ブックマークも保存しなおす（ブックマークを作るあいだだけ、もう一度許可を取る）
        // Minecraft フォルダなら全部のワールドで使う場所として、それ以外はこのワールドの場所として覚える
        if url.startAccessingSecurityScopedResource() {
            if result.fromMinecraftFolder {
                MinecraftFolderStore.save(url)
            } else {
                LevelDatBookmarkStore.save(url, for: newWorld.id)
            }
            url.stopAccessingSecurityScopedResource()
        }
        // 写真が見つかったときだけ、新しい写真にする（level.dat だけのときは、前の写真を残す）
        if let photo = result.photo {
            WorldPhotoStore.shared.save(photo, for: newWorld.id)
        }

        // 通信を待っているあいだに一覧が変わったかもしれないので、場所を探しなおす
        guard let newIndex = worlds.firstIndex(where: { $0.id == newWorld.id })
        else {
            return true  // 一覧からもう消えている → 保存はできているので、成功
        }
        worlds[newIndex] = newWorld  // 画面のデータも、新しい内容に入れかえる
        return true
    }

    // 全部のワールドを読みなおして更新する（写真も新しくなる）
    // 覚えてある Minecraft フォルダから読む。フォルダ名がないワールドは、ワールドごとに覚えた場所から読む
    // どちらもないワールドは、選ぶ画面を出さずに飛ばす（何件もあると、選ぶ画面が続けて出てしまうため）
    func updateAllWorlds() async {
        guard !isUpdatingAll else { return }  // 更新中にもう一度呼ばれたら何もしない
        isUpdatingAll = true  // 更新を始めた
        defer { isUpdatingAll = false }  // この関数を抜けるときに、必ず false に戻す
        updateAllMessage = nil

        // 全部のワールドの ID を、配列に取り出す（updateWorld が途中で worlds を書きかえるため、先に取り出す）
        let ids = worlds.map { $0.id }
        var updatedCount = 0  // 更新できた数
        var failedCount = 0  // 読めなかった・保存できなかった数
        var noBookmarkCount = 0  // ブックマークがない数

        let minecraftFolder = MinecraftFolderStore.resolve()  // 覚えてある Minecraft フォルダ
        for id in ids {
            let hasFolderName = worlds.first { $0.id == id }?.folderName != nil
            let url = hasFolderName ? (minecraftFolder ?? LevelDatBookmarkStore.resolve(for: id)) : LevelDatBookmarkStore.resolve(for: id)
            if let url {
                if await updateWorld(worldId: id, from: url) {
                    updatedCount += 1
                } else {
                    failedCount += 1
                }
            } else {
                noBookmarkCount += 1
            }
        }
        // updateWorld が失敗したときの文が残っているので消す（結果は updateAllMessage で出す）
        errorMessage = nil

        // 結果の文を作る（0 件のものは出さない。2つ目からは改行して並べる）
        var message = "\(updatedCount) 件を更新しました"
        if failedCount > 0 {
            message += "\n\(failedCount) 件は読めませんでした"
        }
        if noBookmarkCount > 0 {
            message += "\n\(noBookmarkCount) 件は、右上の ＋ から Minecraft フォルダを選ぶと更新できます"
        }
        updateAllMessage = message
    }

    func markOpened(worldId: String) {
        // 指定のワールドの日時を今の日時に変更
        openedDates[worldId] = Date()
        WorldOpenedStore.record(Date(), for: worldId)
    }
}
