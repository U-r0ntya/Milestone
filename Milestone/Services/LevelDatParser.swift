import Foundation

// level.dat の読みこみで起きるエラー
enum LevelDatError: Error {
    case missingName  // LevelName がない
    case missingGameMode  // GameType がない、または知らない番号
}

// NBTReader が読んだ辞書から World を作る係
enum LevelDatParser {
    // level.dat の中身から World を作る
    // root：NBTReader.readLevelDat が返した辞書（キーは "LevelName" など）
    // ownerId：ログイン中の人の ID、device：使っている端末の機種
    static func parse(
        _ root: [String: NBTValue],
        ownerId: String,
        device: Device
    ) throws -> World {
        // 必須の2つを取り出す。なければ、読みこみを失敗にする
        // ワールドの名前
        guard let name = root["LevelName"]?.stringValue else {
            throw LevelDatError.missingName
        }
        // ゲームモード（番号を GameMode に直す）
        guard let gameMode = gameMode(from: root["GameType"]?.intValue) else {
            throw LevelDatError.missingGameMode
        }

        // ここから下は任意の項目。level.dat になければ nil のまま
        // シード値
        let seed = root["RandomSeed"]?.intValue
        // 難易度（番号を Difficulty に直す）
        let difficulty = difficulty(from: root["Difficulty"]?.intValue)
        // スポーン地点
        let spawnPoint = spawnPoint(from: root)
        // 最後に開いたバージョン（「1.26.52」の形の文字）
        let lastOpenedVersion = lastOpenedVersion(from: root)
        // ワールドが始まってからの時間（24000 で 1 日）
        let time = root["Time"]?.intValue
        // ワールドの種類（番号を WorldType に直す）
        let worldType = worldType(from: root["Generator"]?.intValue)
        // プレイヤーの権限（番号を PermissionLevel に直す）
        let playerPermission = permission(
            from: root["playerPermissionsLevel"]?.intValue
        )
        // 最後に遊んだ日時（「1970年から何秒」の数を Date に直す）
        var lastPlayed: Date? = nil
        if let seconds = root["LastPlayed"]?.intValue {
            lastPlayed = Date(timeIntervalSince1970: TimeInterval(seconds))
        }
        // コマンド（チート）が有効か。なければ false
        let commandsEnabled = bool(root["commandsEnabled"]) ?? false
        // 一度でもクリエイティブやチートを使ったか
        let hasUsedCheats = bool(root["hasBeenLoadedInCreative"])
        // マルチプレイができるか。なければ true
        let isMultiplayer = bool(root["MultiplayerGame"]) ?? true
        // リソースパックが必須か
        let texturePacksRequired = bool(root["texturePacksRequired"])

        // 読みとった値を World にまとめて返す（引数は World.swift の宣言順）
        return World(
            id: UUID().uuidString,  // アプリが自動で入れる
            ownerId: ownerId,
            device: device,
            createdAt: Date(),  // 登録した日時 = 今
            name: name,
            seed: seed,
            gameMode: gameMode,
            difficulty: difficulty,
            spawnPoint: spawnPoint,
            lastOpenedVersion: lastOpenedVersion,
            lastPlayed: lastPlayed,
            time: time,
            worldType: worldType,
            commandsEnabled: commandsEnabled,
            hasUsedCheats: hasUsedCheats,
            isMultiplayer: isMultiplayer,
            texturePacksRequired: texturePacksRequired,
            playerPermission: playerPermission
        )
    }

    // 番号 → ゲームモード（知らない番号は nil）
    private static func gameMode(from number: Int64?) -> GameMode? {
        switch number {
        case 0:
            return .survival
        case 1:
            return .creative
        case 2:
            return .adventure
        case 6:
            return .spectator
        default:
            return nil
        }
    }

    // 番号 → 難易度
    private static func difficulty(from number: Int64?) -> Difficulty? {
        switch number {
        case 0:
            return .peaceful
        case 1:
            return .easy
        case 2:
            return .normal
        case 3:
            return .hard
        default:
            return nil
        }
    }

    // 番号 → ワールドの種類
    private static func worldType(from number: Int64?) -> WorldType? {
        switch number {
        case 0:
            return .legacy
        case 1:
            return .infinite
        case 2:
            return .flat
        default:
            return nil
        }
    }

    // 番号 → プレイヤーの権限
    private static func permission(from number: Int64?) -> PermissionLevel? {
        switch number {
        case 0:
            return .visitor
        case 1:
            return .member
        case 2:
            return .operator
        default:
            return nil
        }
    }

    // スポーン地点を作る
    private static func spawnPoint(from root: [String: NBTValue])
        -> BlockPosition?
    {
        // X・Z の2つを取り出す。どちらかが取れなければ nil
        // 高さ（SpawnY）は、ほとんどのワールドで「未決定（32767）」のままなので読まない
        guard let x = root["SpawnX"]?.intValue,
            let z = root["SpawnZ"]?.intValue
        else {
            return nil
        }
        // Int64 を Int に直して、1つの位置にまとめる
        return BlockPosition(x: Int(x), z: Int(z))
    }

    // バージョンの文字を作る（数のリスト [1, 26, 52, 3, 0] → "1.26.52"）
    private static func lastOpenedVersion(from root: [String: NBTValue])
        -> String?
    {
        // 数を文字に直したものをためる配列
        var parts: [String] = []
        // リストを取り出す。なければ nil
        guard let versionList = root["lastOpenedWithVersion"]?.listValue
        else {
            return nil
        }
        // 最初の3つだけを順に見て、文字にして足す（数でないものがあれば nil）
        for item in versionList.prefix(3) {
            guard let a = item.intValue else {
                return nil
            }
            parts.append(String(a))
        }
        // 3つそろわなければ nil
        guard parts.count == 3 else { return nil }
        // 「.」でつないで1つの文字にする
        return parts.joined(separator: ".")
    }

    // 0 か 1 の数 → Bool（1 は true、0 は false。値がない・それ以外は nil）
    private static func bool(_ value: NBTValue?) -> Bool? {
        guard let value else {
            return nil
        }
        if value.intValue == 1 {
            return true
        } else if value.intValue == 0 {
            return false
        } else {
            return nil
        }
    }
}
