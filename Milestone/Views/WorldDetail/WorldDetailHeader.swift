import SwiftUI

// ワールドの情報のいちばん上（天気アプリの「都市名と気温」の位置）
// ワールド名・何日目か・ゲームモード・難易度
struct WorldDetailHeader: View {
    let world: World

    // 3 行目：ゲームモード
    private var mainLine: String {
        world.gameMode.displayName
    }

    // 4 行目：難易度（難易度を出すモードで、入っているときだけ）
    private var subLine: String? {
        guard world.gameMode.showsDifficulty, let difficulty = world.difficulty else { return nil }
        return difficulty.displayName
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(world.displayName)
                .font(.system(size: 30, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            if let days = world.days {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(days)")
                        .font(.system(size: 76, weight: .light))
                        .tracking(-1.5)
                        .monospacedDigit()
                    Text("日目")
                        .font(.system(size: 26))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }

            Text(mainLine)
                .font(.system(size: 17, weight: .medium))
                .padding(.top, 2)

            if let subLine {
                Text(subLine)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 2)
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.25), radius: 6, y: 1)  // 空の上でも文字が読めるように
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
