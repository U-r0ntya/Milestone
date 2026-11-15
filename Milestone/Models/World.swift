import Foundation

// ワールド（登録したワールドの情報）
// 必須は、自動で入る4つ（id・ownerId・device・createdAt）と、
// name・gameMode・commandsEnabled・isMultiplayer の4つ。ほかは「詳細」として任意（Optional）
// - Codable：Firestore に保存する・読むため（プロパティの名前がそのままフィールドの名前になる）
// - Identifiable：id を持っている。一覧の ForEach で id: を書かずに使える
// - Hashable：同じかどうかを速く比べられる。一覧から情報の画面へ NavigationLink(value:) で進むのに使う
struct World: Codable, Identifiable, Hashable{
    let id: String  // ワールド ID（アプリが自動で入れる）
    let ownerId: String  // 持ち主のユーザー ID（User から）
    let device: Device  // 機種（User から）
    let createdAt: Date  // 登録した日時（アプリが自動で入れる）
    let name: String  // ワールドの名前（level.dat の LevelName）
    var customName: String? = nil
    let seed: Int64?  // シード値（RandomSeed）
    let gameMode: GameMode  // ゲームモード（GameType）
    let difficulty: Difficulty?  // 難易度（Difficulty）
    let spawnPoint: BlockPosition?  // スポーン地点（SpawnX / Y / Z）
    let lastOpenedVersion: String?  // 最後に開いたバージョン（lastOpenedWithVersion）。「1.21.40」の形
    let lastPlayed: Date?  // 最後に遊んだ日時（LastPlayed）
    let time: Int64?  // ワールドが始まってからの時間（Time。24000 で 1 日）
    let worldType: WorldType?  // ワールドの種類（Generator）
    let commandsEnabled: Bool  // コマンド（チート）が有効か（commandsEnabled）
    let hasUsedCheats: Bool?  // 一度でもクリエイティブやチートを使ったか（hasBeenLoadedInCreative）
    let isMultiplayer: Bool  // マルチプレイができるか（MultiplayerGame）
    let texturePacksRequired: Bool?  // リソースパックが必須か（texturePacksRequired）
    let playerPermission: PermissionLevel?  // プレイヤーの権限（playerPermissionsLevel）
    var folderName: String? = nil  // ワールドのフォルダ名（同じワールドを2回登録しないための目印）
    
    var displayName: String {
        // カスタム名がなければ取得したワールド名を返す
        customName ?? name
    }
}
