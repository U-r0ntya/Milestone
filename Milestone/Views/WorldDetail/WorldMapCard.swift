import SwiftUI

// マップのカード（ランクの下）
// 仮の表示：level.dat には地図のデータがないので、地形は見本の絵。まん中にスポーン地点の印を出す
// 今後、ワールドマップの機能を作ったら、その地図に置きかえる
struct WorldMapCard: View {
    let days: Int?  // スポーン地点の印の中に出す日数（なければピンのアイコン）

    // 見本の地形（横 20 × 縦 14 マス）。数字が色の番号
    private static let terrain: [String] = [
        "33333020222002022222",
        "33333022222222222222",
        "03332222422222222222",
        "23022241111122442414",
        "20222411111124424112",
        "00222111111422222422",
        "00002111112222022222",
        "33302221122203300022",
        "33322241222033333022",
        "33022214222333333222",
        "02222114422333332222",
        "22221111142203322241",
        "42211111122200222411",
        "12411111422200222111",
    ]

    // 色の番号：0 森・1 水・2 草原・3 石・4 砂
    private static let colors: [Color] = [
        Color(hex: 0x3E8A44), Color(hex: 0x4C8DDB), Color(hex: 0x6BB35A),
        Color(hex: 0x8C9096), Color(hex: 0xE4D49B),
    ]

    // 地図の上の文字（白くふちどりして、どの色の上でも読めるようにする）
    private func mapLabel(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(Color(hex: 0x1E2A3A))
            .shadow(color: .white, radius: 1.5)
            .shadow(color: .white, radius: 1.5)
    }

    var body: some View {
        WorldStickyCard(
            title: "マップ",
            systemImage: "map",
            contentPadding: EdgeInsets(top: 0, leading: 14, bottom: 14, trailing: 14)
        ) {
            VStack(alignment: .leading, spacing: 0) {

                ZStack {
                    // 地形（マスを並べて塗る）
                    Canvas { context, size in
                        let cellWidth = size.width / 20
                        let cellHeight = size.height / 14
                        for (row, line) in Self.terrain.enumerated() {
                            for (column, digit) in line.enumerated() {
                                let rect = CGRect(
                                    x: CGFloat(column) * cellWidth,
                                    y: CGFloat(row) * cellHeight,
                                    width: cellWidth + 0.5,  // すき間ができないように少し重ねる
                                    height: cellHeight + 0.5
                                )
                                let color = Self.colors[digit.wholeNumberValue ?? 2]
                                context.fill(Path(rect), with: .color(color))
                            }
                        }
                    }

                    // スポーン地点の印
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.92))
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                            if let days {
                                Text("\(days)")
                                    .font(.system(size: 16, weight: .bold))
                                    .minimumScaleFactor(0.6)
                                    .padding(4)
                            } else {
                                Image(systemName: "mappin")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundStyle(Color(hex: 0x1E2A3A))
                        .frame(width: 44, height: 44)

                        mapLabel("スポーン地点", size: 11)
                    }

                    // 方角
                    mapLabel("N ↑", size: 11)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.trailing, 10)
                        .padding(.bottom, 8)
                }
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("マップの見本。まん中がスポーン地点")

                // 仮の表示であることの説明
                Text("仮の表示です。今後、ワールドマップで表示する予定です。")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 2)
                    .padding(.top, 8)
            }
        }
    }
}
