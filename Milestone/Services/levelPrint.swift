import SwiftUI

// 【一時的な確認用】level.dat を読んで、コンソールに出力する。確認できたらこのファイルごと消す
func printLevelDat() {
    do {
        let url = URL(fileURLWithPath: "/Users/uroncha_mac/Downloads/G-ThHxZK8oY=/level.dat")
        let data = try Data(contentsOf: url)
        let root = try NBTReader.readLevelDat(data)
        // level.dat の中身から World を作る（ownerId と device は確認用の仮の値）
        let world = try LevelDatParser.parse(
            root,
            ownerId: "test",
            device: .iPhone
        )
        // World の項目を、1行に1つずつ出力する
        print("---- World ----")
        for child in Mirror(reflecting: world).children {
            print(child.label ?? "?", ":", child.value)
        }
    } catch {
        print("エラー:", error)
    }
}

// プレビューで表示するだけで、printLevelDat が動く
struct LevelPrintView: View {
    var body: some View {
        Text("level.dat を読んでいます（コンソールを見てください）")
            .onAppear {
                printLevelDat()
            }
    }
}

#Preview {
    LevelPrintView()
}
