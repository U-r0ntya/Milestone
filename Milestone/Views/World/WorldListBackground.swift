import SwiftUI

// ワールドの一覧の背景
// 昼：青い空・太陽・ゆっくり流れるブロックの雲　夜：紺の空・ちかちかする星・ブロックの月
// 空の色は動かないので下に置き、動くもの（太陽・雲・星・月）だけを TimelineView で描きなおす
struct WorldListBackground: View {
    let isNight: Bool
    var showsSunAndMoon: Bool = true  // 太陽と月を出すか（登録のシートでは出さない）
    @Environment(\.accessibilityReduceMotion) private var reduceMotion  // 「視差効果を減らす」なら止める

    var body: some View {
        ZStack {
            sky
            // アプリに自分の TimelineView があるので、SwiftUI のものと名前で区別する
            SwiftUI.TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
                Canvas { context, size in
                    let painter = WorldListBackgroundPainter(
                        time: timeline.date.timeIntervalSinceReferenceDate
                    )
                    // デザインは幅 390 で作ったので、画面の幅に合わせて大きさをそろえる
                    let scale = size.width / 390
                    context.scaleBy(x: scale, y: scale)
                    if isNight {
                        painter.drawStars(in: &context, height: size.height / scale)
                        if showsSunAndMoon { painter.drawMoon(in: &context) }
                    } else {
                        if showsSunAndMoon { painter.drawSun(in: &context) }
                        painter.drawClouds(in: &context, height: size.height / scale)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    // 空の色（上から下へのグラデーション）
    private var sky: LinearGradient {
        LinearGradient(
            colors: isNight
                ? [Color(hex: 0x0B1030), Color(hex: 0x1B2352), Color(hex: 0x2A3270)]
                : [Color(hex: 0x3E8DDB), Color(hex: 0x6FB1EA), Color(hex: 0x8EC4F0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// 背景の動くものを描く（time：今の時刻。ここから位置や明るさを計算する）
private struct WorldListBackgroundPainter {
    let time: Double

    // 星の位置・大きさ・ちかちかの速さ（毎回同じ並びになるように、決まった式で作る）
    private struct Star {
        let x: Double
        let y: Double
        let size: Double
        let delay: Double
        let period: Double
    }

    private static let stars: [Star] = {
        var seed = 7
        func random() -> Double {
            seed = (seed * 9301 + 49297) % 233280
            return Double(seed) / 233280
        }
        let sizes: [Double] = [3, 3, 4, 4, 5]
        return (0..<46).map { _ in
            let x = (random() * 380).rounded()
            let y = random()  // 0〜1。画面の高さに合わせて、描くときに広げる
            let size = sizes[Int(random() * 5)]
            let delay = random() * 3
            let period = 2 + random() * 2.4
            return Star(x: x, y: y, size: size, delay: delay, period: period)
        }
    }()

    // 0 → 1 → 0 と、なめらかに行ったり来たりする値（period 秒で 1 往復）
    private func wave(period: Double, delay: Double = 0) -> Double {
        0.5 - 0.5 * cos(2 * .pi * (time - delay) / period)
    }

    // 0 → 1 に進んで、また 0 から始まる値（period 秒で 1 周）
    private func loop(period: Double, delay: Double = 0) -> Double {
        let value = ((time - delay) / period).truncatingRemainder(dividingBy: 1)
        return value < 0 ? value + 1 : value
    }

    // MARK: - 夜

    func drawStars(in context: inout GraphicsContext, height: Double) {
        for star in Self.stars {
            let rect = CGRect(x: star.x, y: star.y * (height - 20), width: star.size, height: star.size)
            let opacity = 0.25 + 0.75 * wave(period: star.period, delay: star.delay)
            context.fill(Path(rect), with: .color(.white.opacity(opacity)))
        }
    }

    func drawMoon(in context: inout GraphicsContext) {
        var g = context  // GraphicsContext は値なので、コピーして動かしても元はそのまま
        bob(&g, center: CGPoint(x: 310, y: 120))
        let moon = CGRect(x: 286, y: 96, width: 48, height: 48)
        glow(&g, around: moon, color: Color(hex: 0xC8D2FF, opacity: 0.35), radius: 70)
        g.fill(Path(moon), with: .color(Color(hex: 0xE8ECFF)))
        g.fill(Path(CGRect(x: 302, y: 108, width: 12, height: 12)), with: .color(Color(hex: 0xC9D0F0)))
    }

    // MARK: - 昼

    func drawSun(in context: inout GraphicsContext) {
        var g = context
        bob(&g, center: CGPoint(x: 304, y: 124))
        let sun = CGRect(x: 276, y: 96, width: 56, height: 56)
        glow(&g, around: sun, color: Color(hex: 0xFFE066, opacity: 0.55), radius: 80)
        g.fill(Path(sun), with: .color(Color(hex: 0xFFE066)))
    }

    // 雲の形（0〜1 の点で書いた、ブロックの雲の形）
    private static let cloudShapes: [[CGPoint]] = [
        [
            CGPoint(x: 0, y: 1), CGPoint(x: 0, y: 0.4), CGPoint(x: 0.2, y: 0.4), CGPoint(x: 0.2, y: 0),
            CGPoint(x: 0.6, y: 0), CGPoint(x: 0.6, y: 0.3), CGPoint(x: 0.8, y: 0.3), CGPoint(x: 0.8, y: 0.6),
            CGPoint(x: 1, y: 0.6), CGPoint(x: 1, y: 1),
        ],
        [
            CGPoint(x: 0, y: 1), CGPoint(x: 0, y: 0.5), CGPoint(x: 0.25, y: 0.5), CGPoint(x: 0.25, y: 0),
            CGPoint(x: 0.7, y: 0), CGPoint(x: 0.7, y: 0.5), CGPoint(x: 1, y: 0.5), CGPoint(x: 1, y: 1),
        ],
        [
            CGPoint(x: 0, y: 1), CGPoint(x: 0, y: 0.45), CGPoint(x: 0.15, y: 0.45), CGPoint(x: 0.15, y: 0),
            CGPoint(x: 0.55, y: 0), CGPoint(x: 0.55, y: 0.35), CGPoint(x: 0.85, y: 0.35), CGPoint(x: 0.85, y: 0.6),
            CGPoint(x: 1, y: 0.6), CGPoint(x: 1, y: 1),
        ],
    ]

    // 雲 1 つの決まり（y は画面の高さの割合。下に行くほど、少しうすく・ゆっくりにして奥行きを出す）
    private struct Cloud {
        let shape: Int
        let y: Double
        let width: Double
        let height: Double
        let opacity: Double
        let period: Double
        let delay: Double
    }

    private static let clouds: [Cloud] = [
        Cloud(shape: 0, y: 0.07, width: 110, height: 26, opacity: 0.72, period: 70, delay: 0),
        Cloud(shape: 1, y: 0.20, width: 84, height: 22, opacity: 0.54, period: 95, delay: -45),
        Cloud(shape: 2, y: 0.31, width: 150, height: 34, opacity: 0.62, period: 80, delay: -20),
        Cloud(shape: 1, y: 0.42, width: 96, height: 24, opacity: 0.5, period: 105, delay: -70),
        Cloud(shape: 0, y: 0.53, width: 130, height: 30, opacity: 0.6, period: 85, delay: -10),
        Cloud(shape: 2, y: 0.64, width: 104, height: 26, opacity: 0.48, period: 110, delay: -88),
        Cloud(shape: 1, y: 0.75, width: 160, height: 36, opacity: 0.58, period: 90, delay: -35),
        Cloud(shape: 0, y: 0.87, width: 90, height: 22, opacity: 0.46, period: 100, delay: -60),
    ]

    func drawClouds(in context: inout GraphicsContext, height: Double) {
        // 左の画面の外（-220）から、右の画面の外（460）まで流れる
        for cloud in Self.clouds {
            drawCloud(
                &context,
                shape: Self.cloudShapes[cloud.shape],
                x: -220 + 680 * loop(period: cloud.period, delay: cloud.delay),
                y: cloud.y * height,
                width: cloud.width,
                height: cloud.height,
                opacity: cloud.opacity
            )
        }
    }

    // MARK: - 部品

    // 雲 1 つ（shape：0〜1 の点で書いた、ブロックの雲の形）
    private func drawCloud(
        _ context: inout GraphicsContext,
        shape: [CGPoint],
        x: Double, y: Double, width: Double, height: Double, opacity: Double
    ) {
        var path = Path()
        path.addLines(shape.map { CGPoint(x: x + $0.x * width, y: y + $0.y * height) })
        path.closeSubpath()
        context.fill(path, with: .color(.white.opacity(opacity)))
    }

    // 太陽と月を、7 秒でゆっくり上下させながら少し傾ける
    private func bob(_ context: inout GraphicsContext, center: CGPoint) {
        let amount = wave(period: 7)
        context.translateBy(x: center.x, y: center.y + 8 * amount)
        context.rotate(by: .degrees(6 * amount))
        context.translateBy(x: -center.x, y: -center.y)
    }

    // まわりのぼんやりした光（まん中が濃く、外に向かって消える）
    private func glow(_ context: inout GraphicsContext, around rect: CGRect, color: Color, radius: Double) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let area = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(
            Path(ellipseIn: area),
            with: .radialGradient(
                Gradient(colors: [color, color.opacity(0)]),
                center: center,
                startRadius: rect.width / 2,
                endRadius: radius
            )
        )
    }
}

#Preview("昼") {
    WorldListBackground(isNight: false).ignoresSafeArea()
}

#Preview("夜") {
    WorldListBackground(isNight: true).ignoresSafeArea()
}
