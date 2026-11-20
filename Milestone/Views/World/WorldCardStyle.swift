import SwiftUI

// ワールドのカード（写真カード）の、枠・バッジの色と、左上のバッジの文字
// ランクがあるワールド（サバイバルで日数がある）は、ランクの素材の色と「RANK Gold」
// ランクがないワールドは、ゲームモードの色と「CREATIVE」など
struct WorldCardStyle {
    let label: String  // 左上のバッジの文字
    private let palette: WorldCardPalette

    init(world: World) {
        if world.gameMode == .survival, world.time != nil {
            let rank = WorldRank(world: world)
            var text = "RANK \(rank.tier.englishName)"
            if let level = rank.level {
                text += " Lv.\(level)"  // ネザライトは Lv. も出す
            }
            label = text
            palette = rank.tier.cardPalette
        } else {
            label = world.gameMode.englishName
            palette = world.gameMode.cardPalette
        }
    }

    // 枠のグラデーション（左上 → まん中 → 右下）
    // ダーク：元の色から、右下に向かって暗く沈む
    // ライト：元の色を主体に、右下は白に近づく（黒に落とすと、明るい背景で枠が消えるため）
    func frameGradient(isDark: Bool) -> LinearGradient {
        let colors: [Color]
        if isDark {
            colors = [palette.hi.color(opacity: 0.95), palette.mid.color(), palette.lo.color()]
        } else if let light = palette.light {
            colors = light.map { $0.color() }
        } else {
            colors = [palette.hi.color(), palette.hi.scaled(0.92).color(), palette.hi.tinted(0.88).color()]
        }
        return LinearGradient(
            stops: [
                .init(color: colors[0], location: 0),
                .init(color: colors[1], location: 0.4),
                .init(color: colors[2], location: 1),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // カードの外側の、ほのかな光（ダークだけ）
    func glow(isDark: Bool) -> Color {
        isDark ? palette.glow.color() : .clear
    }
}

// 色を数字で持つ（0〜255）。白に近づけたり、暗くしたりする計算に使う
struct CardRGB {
    let r: Double
    let g: Double
    let b: Double
    var a: Double = 1

    func color(opacity: Double? = nil) -> Color {
        Color(red: r / 255, green: g / 255, blue: b / 255, opacity: opacity ?? a)
    }

    // k 倍の明るさにする（1 より小さいと暗くなる）
    func scaled(_ k: Double) -> CardRGB {
        CardRGB(r: min(255, r * k), g: min(255, g * k), b: min(255, b * k))
    }

    // 白に近づける（t = 0 で元の色、1 で白）
    func tinted(_ t: Double) -> CardRGB {
        CardRGB(r: r + (255 - r) * t, g: g + (255 - g) * t, b: b + (255 - b) * t)
    }
}

// 1つのランク（またはゲームモード）の色
struct WorldCardPalette {
    let hi: CardRGB  // 元の色（左上）
    let mid: CardRGB  // ダークのまん中（半透明）
    let lo: CardRGB  // ダークの右下（半透明）
    let glow: CardRGB  // ダークの外側の光
    var light: [CardRGB]? = nil  // ライトの色を決めて使うとき（ネザライト）
}

extension WorldRank.Tier {
    // バッジに出す英語の名前
    var englishName: String {
        switch self {
        case .wood: "Wood"
        case .stone: "Stone"
        case .copper: "Copper"
        case .iron: "Iron"
        case .gold: "Gold"
        case .diamond: "Diamond"
        case .netherite: "Netherite"
        }
    }

    var cardPalette: WorldCardPalette {
        switch self {
        case .wood:
            WorldCardPalette(
                hi: CardRGB(r: 205, g: 160, b: 105), mid: CardRGB(r: 130, g: 90, b: 50, a: 0.55),
                lo: CardRGB(r: 60, g: 40, b: 22, a: 0.35), glow: CardRGB(r: 190, g: 140, b: 90, a: 0.2))
        case .stone:
            WorldCardPalette(
                hi: CardRGB(r: 190, g: 194, b: 200), mid: CardRGB(r: 120, g: 125, b: 132, a: 0.55),
                lo: CardRGB(r: 60, g: 63, b: 68, a: 0.35), glow: CardRGB(r: 160, g: 165, b: 172, a: 0.2))
        case .copper:
            WorldCardPalette(
                hi: CardRGB(r: 230, g: 150, b: 100), mid: CardRGB(r: 160, g: 90, b: 55, a: 0.55),
                lo: CardRGB(r: 70, g: 40, b: 25, a: 0.35), glow: CardRGB(r: 220, g: 140, b: 90, a: 0.22))
        case .iron:
            WorldCardPalette(
                hi: CardRGB(r: 225, g: 225, b: 230), mid: CardRGB(r: 150, g: 152, b: 160, a: 0.55),
                lo: CardRGB(r: 70, g: 72, b: 78, a: 0.35), glow: CardRGB(r: 200, g: 202, b: 210, a: 0.2))
        case .gold:
            WorldCardPalette(
                hi: CardRGB(r: 240, g: 200, b: 90), mid: CardRGB(r: 170, g: 130, b: 40, a: 0.55),
                lo: CardRGB(r: 80, g: 60, b: 20, a: 0.35), glow: CardRGB(r: 230, g: 190, b: 70, a: 0.22))
        case .diamond:
            WorldCardPalette(
                hi: CardRGB(r: 120, g: 235, b: 235), mid: CardRGB(r: 50, g: 160, b: 170, a: 0.55),
                lo: CardRGB(r: 20, g: 70, b: 80, a: 0.35), glow: CardRGB(r: 90, g: 220, b: 225, a: 0.22))
        case .netherite:
            WorldCardPalette(
                hi: CardRGB(r: 176, g: 140, b: 235), mid: CardRGB(r: 88, g: 62, b: 140, a: 0.65),
                lo: CardRGB(r: 24, g: 16, b: 40, a: 0.7), glow: CardRGB(r: 150, g: 110, b: 220, a: 0.22),
                light: [
                    CardRGB(r: 176, g: 140, b: 235), CardRGB(r: 70, g: 48, b: 120),
                    CardRGB(r: 234, g: 228, b: 246),
                ])
        }
    }
}

extension GameMode {
    // バッジに出す英語の名前（ランクがないワールド）
    var englishName: String {
        switch self {
        case .survival: "SURVIVAL"
        case .creative: "CREATIVE"
        case .adventure: "ADVENTURE"
        case .spectator: "SPECTATOR"
        }
    }

    var cardPalette: WorldCardPalette {
        switch self {
        case .survival:
            WorldCardPalette(
                hi: CardRGB(r: 120, g: 232, b: 168), mid: CardRGB(r: 52, g: 178, b: 124, a: 0.55),
                lo: CardRGB(r: 22, g: 90, b: 70, a: 0.35), glow: CardRGB(r: 110, g: 220, b: 160, a: 0.2))
        case .creative:
            WorldCardPalette(
                hi: CardRGB(r: 190, g: 168, b: 255), mid: CardRGB(r: 124, g: 98, b: 224, a: 0.55),
                lo: CardRGB(r: 50, g: 38, b: 120, a: 0.35), glow: CardRGB(r: 170, g: 150, b: 250, a: 0.2))
        case .adventure:
            WorldCardPalette(
                hi: CardRGB(r: 255, g: 206, b: 120), mid: CardRGB(r: 232, g: 140, b: 52, a: 0.55),
                lo: CardRGB(r: 120, g: 60, b: 15, a: 0.35), glow: CardRGB(r: 250, g: 190, b: 100, a: 0.2))
        case .spectator:
            WorldCardPalette(
                hi: CardRGB(r: 170, g: 190, b: 220), mid: CardRGB(r: 100, g: 115, b: 150, a: 0.55),
                lo: CardRGB(r: 40, g: 48, b: 70, a: 0.35), glow: CardRGB(r: 160, g: 180, b: 215, a: 0.2))
        }
    }
}
