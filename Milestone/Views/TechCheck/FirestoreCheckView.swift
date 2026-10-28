import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// 技術検証用：セキュリティルールで「ワールドは本人だけ」が守られるか確かめる（確かめたら消す）
struct FirestoreCheckView: View {
    @State private var log: [String] = []
    private let db = Firestore.firestore()

    // 今ログインしている人の uid
    private var uid: String? {
        Auth.auth().currentUser?.uid
    }

    var body: some View {
        NavigationStack {
            List {
                Section("試す") {
                    Button("① 自分のワールドを保存する") {
                        Task { await saveMyWorld() }
                    }
                    Button("② 自分のワールドを読む") {
                        Task { await readMyWorlds() }
                    }
                    Button("③ 他人のワールドを読む（失敗すれば正解）") {
                        Task { await readOthersWorld() }
                    }
                    Button("④ 全員のワールドを読む（失敗すれば正解）") {
                        Task { await readAllWorlds() }
                    }
                }
                Section("結果（新しい順）") {
                    ForEach(log.indices.reversed(), id: \.self) { index in
                        Text(log[index])
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Firestore（検証）")
        }
    }

    // ① 持ち主を自分にして保存する → 成功するはず
    private func saveMyWorld() async {
        guard let uid else {
            log.append("ログインしていません")
            return
        }
        do {
            try await db.collection("worlds").addDocument(data: [
                "ownerId": uid,
                "name": "検証用ワールド",
                "gameMode": "survival",
                "commandsEnabled": false,
                "isMultiplayer": true,
                "createdAt": FieldValue.serverTimestamp()
            ])
            log.append("① 成功：保存できた")
        } catch {
            log.append("① 失敗：\(error.localizedDescription)")
        }
    }

    // ② 持ち主が自分のものだけを探して読む → 成功するはず
    private func readMyWorlds() async {
        guard let uid else {
            log.append("ログインしていません")
            return
        }
        do {
            let snapshot = try await db.collection("worlds")
                .whereField("ownerId", isEqualTo: uid)
                .getDocuments()
            let names = snapshot.documents.compactMap { $0.data()["name"] as? String }
            log.append("② 成功：\(names.count) 件（\(names.joined(separator: "、"))）")
        } catch {
            log.append("② 失敗：\(error.localizedDescription)")
        }
    }

    // ③ 他人のワールドを ID で直接読む → 失敗するのが正しい
    private func readOthersWorld() async {
        do {
            _ = try await db.collection("worlds").document("otherWorld").getDocument()
            log.append("③ 読めてしまった（ルールがおかしい）")
        } catch {
            log.append("③ 正しく失敗：\(error.localizedDescription)")
        }
    }

    // ④ 条件を付けずに全部読む → 失敗するのが正しい
    private func readAllWorlds() async {
        do {
            let snapshot = try await db.collection("worlds").getDocuments()
            log.append("④ 読めてしまった：\(snapshot.documents.count) 件（ルールがおかしい）")
        } catch {
            log.append("④ 正しく失敗：\(error.localizedDescription)")
        }
    }
}
