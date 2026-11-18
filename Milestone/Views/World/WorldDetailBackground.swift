import SwiftUI

// ワールドの情報の背景：ブロックでできた空と、地面の下（土 → 石 → 深層岩 → 岩盤 → 奈落）
// デザイン（幅 390 の画面）の座標のまま描き、画面の幅に合わせて拡大・縮小する
// - 空：y = 0〜460（太陽・雲・星・丘・ゲート・旅人・ほたる）
// - 地面の下：y = 460〜（洞窟・松明・鍾乳洞。いちばん下の奈落は、どこまでも続く）
// スクロールに合わせて、絵も上に動かす（scrollOffset）
struct WorldDetailBackground: View {
    let palette: WorldDetailPalette  // 昼か夜かの色
    let scrollOffset: CGFloat  // 下に何ポイントスクロールしたか
    @Environment(\.accessibilityReduceMotion) private var reduceMotion  // 「視差効果を減らす」がオンなら、動きを止める

    var body: some View {
        // 1 秒に 30 回くらい描きなおして、雲やほたるを動かす
        SwiftUI.TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let scale = size.width / 390  // デザインの 1 が、画面の何ポイントか
                context.scaleBy(x: scale, y: scale)
                context.translateBy(x: 0, y: -scrollOffset / scale)

                let painter = WorldBackgroundPainter(
                    palette: palette,
                    time: timeline.date.timeIntervalSinceReferenceDate
                )
                painter.drawSky(in: context)
                painter.drawUnderground(in: context)
            }
        }
        .accessibilityHidden(true)  // 飾りなので、VoiceOver では読まない
    }
}

// 背景の色（昼と夜）
struct WorldDetailPalette {
    let sky: Color
    let sun: Color
    let sunGlow: Color
    let hillFar: Color  // 遠い丘
    let hillNear: Color  // 近い丘（土）
    let grass: Color
    let dirt: Color
    let stone: Color
    let deep: Color  // 深層岩
    let cave: Color
    let drip: Color  // 鍾乳石
    let dripTop: Color  // 鍾乳洞の天井
    let bedrock: Color
    let void: Color  // 奈落
    let showsStars: Bool  // 星を出すか（夜だけ）

    static let day = WorldDetailPalette(
        sky: Color(hex: 0x79B8EE),
        sun: Color(hex: 0xFFE066),
        sunGlow: Color(hex: 0xFFE066, opacity: 0.55),
        hillFar: Color(hex: 0x5A9BB8),
        hillNear: Color(hex: 0x7A5230),
        grass: Color(hex: 0x5DB04A),
        dirt: Color(hex: 0x7A5230),
        stone: Color(hex: 0x7B7F86),
        deep: Color(hex: 0x4A4E57),
        cave: Color(hex: 0x34373E),
        drip: Color(hex: 0xA07C5B),
        dripTop: Color(hex: 0xB39172),
        bedrock: Color(hex: 0x1A1B1F),
        void: Color(hex: 0x050506),
        showsStars: false
    )

    static let night = WorldDetailPalette(
        sky: Color(hex: 0x1B2352),
        sun: Color(hex: 0xE8ECFF),
        sunGlow: Color(hex: 0xC8D2FF, opacity: 0.35),
        hillFar: Color(hex: 0x1C3A52),
        hillNear: Color(hex: 0x3B2A1E),
        grass: Color(hex: 0x2E7D4F),
        dirt: Color(hex: 0x3B2A1E),
        stone: Color(hex: 0x3D4047),
        deep: Color(hex: 0x23262D),
        cave: Color(hex: 0x171A20),
        drip: Color(hex: 0x6E543E),
        dripTop: Color(hex: 0x7C5F47),
        bedrock: Color(hex: 0x0E0F12),
        void: Color(hex: 0x050506),
        showsStars: true
    )
}

extension Color {
    // 0xRRGGBB の形で色を作る（デザインの色をそのまま書くため）
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// 実際に描く係（座標はすべてデザインの座標）
private struct WorldBackgroundPainter {
    let palette: WorldDetailPalette
    let time: TimeInterval  // 今の時刻（秒）。動きの計算に使う

    private var ground: CGFloat { 460 }  // 地面の下が始まる y
    private var endless: CGFloat { 100_000 }  // 「どこまでも下」の代わりの大きな数

    // MARK: - 動きの計算

    // 0 → 1 → 0 となめらかに行き来する値（period 秒で 1 往復。delay 秒ずらす）
    private func wave(period: Double, delay: Double = 0) -> Double {
        0.5 - 0.5 * cos(2 * .pi * (time - delay) / period)
    }

    // 0 → 1 に進んで、また 0 から始まる値（period 秒で 1 周）
    private func loop(period: Double, delay: Double = 0) -> Double {
        let value = ((time - delay) / period).truncatingRemainder(dividingBy: 1)
        return value < 0 ? value + 1 : value
    }

    // MARK: - 形を作る

    // 点をつないだ形（dy だけ下にずらせる）
    private func polygon(_ points: [(CGFloat, CGFloat)], dy: CGFloat = 0) -> Path {
        Path { path in
            path.addLines(points.map { CGPoint(x: $0.0, y: $0.1 + dy) })
            path.closeSubpath()
        }
    }

    // 割合（0〜1）で書いた点を、四角の中の点にしてつないだ形
    private func polygon(_ points: [(CGFloat, CGFloat)], in rect: CGRect) -> Path {
        polygon(points.map { (rect.minX + $0.0 * rect.width, rect.minY + $0.1 * rect.height) })
    }

    private func fillRect(
        _ context: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
        _ color: Color
    ) {
        context.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
    }

    // MARK: - 空

    func drawSky(in context: GraphicsContext) {
        // 空の色（上に引っぱったときに見えるところも塗る）
        fillRect(context, 0, -endless, 390, endless + ground, palette.sky)

        if palette.showsStars { drawStars(in: context) }
        drawSun(in: context)
        drawClouds(in: context)
        drawHills(in: context)
        drawGate(in: context)
        drawTraveler(in: context)
        drawFireflies(in: context)
    }

    // 星（夜だけ。ちかちか光る）
    private func drawStars(in context: GraphicsContext) {
        let stars: [(CGFloat, CGFloat, Double)] = [
            (40, 70, 0), (120, 130, 0.8), (210, 60, 1.5), (300, 110, 0.3),
            (350, 190, 2), (70, 220, 1.1), (260, 230, 1.9),
        ]
        for (x, y, delay) in stars {
            var g = context
            g.opacity = 0.25 + 0.75 * wave(period: 2.6, delay: delay)
            fillRect(g, x, y, 4, 4, .white)
        }
    }

    // 太陽（夜は月）：7 秒で、ゆっくり上下して少し回る
    private func drawSun(in context: GraphicsContext) {
        let move = wave(period: 7)
        var g = context
        g.translateBy(x: 298, y: 114 + 8 * move)  // 太陽のまん中
        g.rotate(by: .degrees(6 * move))

        // まわりの光（ぼかした大きな四角）
        var glow = g
        glow.addFilter(.blur(radius: 30))
        glow.fill(Path(CGRect(x: -46, y: -46, width: 92, height: 92)), with: .color(palette.sunGlow))

        g.fill(Path(CGRect(x: -28, y: -28, width: 56, height: 56)), with: .color(palette.sun))
    }

    // 雲：左から右へ流れる（3 つ。遠いものほどゆっくり・うすい）
    private func drawClouds(in context: GraphicsContext) {
        struct Cloud {
            let y: CGFloat, width: CGFloat, height: CGFloat
            let opacity: Double, period: Double, delay: Double
            let shape: [(CGFloat, CGFloat)]
        }
        let clouds = [
            Cloud(
                y: 60, width: 120, height: 28, opacity: 1, period: 46, delay: 0,
                shape: [(0, 1), (0, 0.4), (0.2, 0.4), (0.2, 0), (0.6, 0), (0.6, 0.3), (0.8, 0.3), (0.8, 0.6), (1, 0.6), (1, 1)]
            ),
            Cloud(
                y: 150, width: 90, height: 24, opacity: 0.7, period: 62, delay: -30,
                shape: [(0, 1), (0, 0.5), (0.25, 0.5), (0.25, 0), (0.7, 0), (0.7, 0.5), (1, 0.5), (1, 1)]
            ),
            Cloud(
                y: 215, width: 140, height: 30, opacity: 0.55, period: 80, delay: -55,
                shape: [(0, 1), (0, 0.45), (0.15, 0.45), (0.15, 0), (0.55, 0), (0.55, 0.35), (0.85, 0.35), (0.85, 0.6), (1, 0.6), (1, 1)]
            ),
        ]
        for cloud in clouds {
            let x = -220 + 680 * loop(period: cloud.period, delay: cloud.delay)  // 画面の左の外 → 右の外
            var g = context
            g.opacity = 0.88 * cloud.opacity
            g.fill(
                polygon(cloud.shape, in: CGRect(x: x, y: cloud.y, width: cloud.width, height: cloud.height)),
                with: .color(.white)
            )
        }
    }

    // 丘：遠い丘、近い丘（土）、その上の草
    private func drawHills(in context: GraphicsContext) {
        let far = CGRect(x: 0, y: 270, width: 390, height: 120)
        context.fill(
            polygon(
                [(0, 0.6), (0.12, 0.6), (0.12, 0.35), (0.3, 0.35), (0.3, 0.55), (0.48, 0.55), (0.48, 0.2),
                 (0.66, 0.2), (0.66, 0.45), (0.84, 0.45), (0.84, 0.3), (1, 0.3), (1, 1), (0, 1)],
                in: far
            ),
            with: .color(palette.hillFar)
        )

        let near = CGRect(x: 0, y: 350, width: 390, height: 110)
        context.fill(
            polygon(
                [(0, 0.45), (0.16, 0.45), (0.16, 0.65), (0.34, 0.65), (0.34, 0.3), (0.52, 0.3), (0.52, 0.55),
                 (0.74, 0.55), (0.74, 0.38), (1, 0.38), (1, 1), (0, 1)],
                in: near
            ),
            with: .color(palette.hillNear)
        )
        context.fill(
            polygon(
                [(0, 0.45), (0.16, 0.45), (0.16, 0.65), (0.34, 0.65), (0.34, 0.3), (0.52, 0.3), (0.52, 0.55),
                 (0.74, 0.55), (0.74, 0.38), (1, 0.38), (1, 0.46), (0.74, 0.46), (0.74, 0.63), (0.52, 0.63),
                 (0.52, 0.38), (0.34, 0.38), (0.34, 0.73), (0.16, 0.73), (0.16, 0.53), (0, 0.53)],
                in: near
            ),
            with: .color(palette.grass)
        )
    }

    // MARK: - ゲート（右の地面。斜めに置いて、奥に 1 ブロック分の厚み）

    // ゲートの面の点（左上が 0,0、幅 72・高さ 94。z は奥がマイナス）を、画面の点にする
    // CSS の perspective(260px) rotateY(-42deg)（下の辺のまん中を中心に回す）と同じ計算
    private func gatePoint(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat = 0) -> CGPoint {
        let angle = -42 * CGFloat.pi / 180
        let rx = x - 36  // 回す中心からの位置
        let ry = y - 94
        let x2 = rx * cos(angle) + z * sin(angle)
        let z2 = -rx * sin(angle) + z * cos(angle)
        let s = 260 / (260 - z2)  // 手前ほど大きく見せる
        return CGPoint(x: 332 + x2 * s, y: 394 + ry * s)
    }

    // ゲートの正面の四角
    private func gateFront(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
        Path { path in
            path.addLines([
                gatePoint(x, y), gatePoint(x + w, y), gatePoint(x + w, y + h), gatePoint(x, y + h),
            ])
            path.closeSubpath()
        }
    }

    // ゲートの右の側面の四角（奥行き 18）
    private func gateSide(_ y: CGFloat, _ h: CGFloat) -> Path {
        Path { path in
            path.addLines([
                gatePoint(72, y), gatePoint(72, y, -18), gatePoint(72, y + h, -18), gatePoint(72, y + h),
            ])
            path.closeSubpath()
        }
    }

    private func drawGate(in context: GraphicsContext) {
        // 側面（黒曜石の厚み）
        context.fill(gateSide(0, 94), with: .color(Color(hex: 0x130A20)))
        context.fill(gateSide(36, 18), with: .color(Color(hex: 0x241539)))

        // 正面（紫に光る）
        var front = context
        front.addFilter(.shadow(color: Color(hex: 0xAA5AFF, opacity: 0.55), radius: 14))
        front.fill(gateFront(0, 0, 72, 94), with: .color(Color(hex: 0x1E1230)))

        // 少し明るいブロック
        for (x, y) in [(CGFloat(0), CGFloat(0)), (54, 36), (0, 76)] {
            context.fill(gateFront(x, y, 18, 18), with: .color(Color(hex: 0x2E1B4A)))
        }

        // 中のうず（明るさがゆっくり変わる）
        let portal = gateFront(18, 18, 36, 58)
        var inner = context
        inner.opacity = 0.85 + 0.15 * wave(period: 3)
        inner.fill(
            portal,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(hex: 0x6A2BC4), location: 0),
                    .init(color: Color(hex: 0xB05CFF), location: 0.55),
                    .init(color: Color(hex: 0x8A3FE0), location: 1),
                ]),
                startPoint: gatePoint(26, 18),
                endPoint: gatePoint(46, 76)
            )
        )

        // うずから上がる粒（うずの外には出さない）
        inner.clip(to: portal)
        let motes: [(CGFloat, CGFloat, Double)] = [(6, 47, 0), (18, 51, 1), (27, 43, 1.8)]
        for (x, y, delay) in motes {
            let progress = loop(period: 2.6, delay: delay)
            var g = inner
            g.opacity = progress < 0.2 ? progress / 0.2 : (1 - progress) / 0.8
            g.fill(
                gateFront(18 + x, 18 + y - 44 * progress, 5, 5),
                with: .color(Color(hex: 0xE8C9FF))
            )
        }
    }

    // MARK: - 旅人（左端にもたれて、空を見上げる）

    private func drawTraveler(in context: GraphicsContext) {
        var g = context
        // 体ぜんたいを、足もとを中心に少し傾ける
        g.translateBy(x: 30, y: 401)
        g.rotate(by: .degrees(-10))
        g.translateBy(x: -20, y: -58)  // ここからは、体の四角（幅 40・高さ 58）の中の座標

        // 後ろの足とブーツ
        fillRect(g, 5, 38, 10, 20, Color(hex: 0x3A3F4A))
        fillRect(g, 5, 52, 10, 6, Color(hex: 0x5B3A22))

        // 前に出した足（ももの付け根を中心に回す）
        var leg = g
        leg.translateBy(x: 20, y: 38)
        leg.rotate(by: .degrees(-22))
        leg.translateBy(x: -5, y: 0)
        fillRect(leg, 0, 0, 10, 20, Color(hex: 0x3A3F4A))
        fillRect(leg, 0, 14, 14, 6, Color(hex: 0x5B3A22))

        // 体・スカーフ・腕
        fillRect(g, 3, 14, 26, 24, Color(hex: 0xB3342E))
        fillRect(g, 3, 14, 26, 6, Color(hex: 0xF0B429))
        fillRect(g, 20, 20, 6, 12, Color(hex: 0xF0B429))
        fillRect(g, 22, 22, 14, 7, Color(hex: 0x8E2823))

        // 手に持った板
        var board = g
        board.translateBy(x: 37.5, y: 21.5)
        board.rotate(by: .degrees(-12))
        fillRect(board, -4.5, -1.5, 9, 3, Color(hex: 0xD9DDE2))
        fillRect(g, 34, 24, 5, 5, Color(hex: 0xE2B58F))

        // 頭（あごの後ろを中心に、上を向かせる）
        var head = g
        head.translateBy(x: 7 + 6.6, y: 14)
        head.rotate(by: .degrees(-20))
        head.translateBy(x: -6.6, y: -18)
        fillRect(head, 0, 0, 22, 18, Color(hex: 0xE2B58F))
        fillRect(head, 0, 0, 22, 7, Color(hex: 0xD9D9D9))
        fillRect(head, 0, 0, 8, 18, Color(hex: 0xD9D9D9))
        fillRect(head, 15, 6, 3, 3, Color(hex: 0x2B1B14))
    }

    // ほたる：地面から、ふわっと上がって消える
    private func drawFireflies(in context: GraphicsContext) {
        let flies: [(CGFloat, CGFloat, Double)] = [(90, 395, 0), (200, 415, 1.7), (310, 385, 3.2)]
        for (x, y, delay) in flies {
            let progress = loop(period: 5, delay: delay)
            var g = context
            g.opacity = progress < 0.15 ? 0.9 * progress / 0.15 : 0.9 * (1 - progress) / 0.85
            fillRect(g, x, y - 120 * progress, 5, 5, Color(hex: 0xFFE97A))
        }
    }

    // MARK: - 地面の下

    func drawUnderground(in context: GraphicsContext) {
        let dy = ground
        fillRect(context, 0, dy, 390, endless, palette.dirt)  // 土

        // 石（上の境目はジグザグ）
        context.fill(
            polygon(
                [(0, 110), (30, 110), (30, 80), (90, 80), (90, 140), (120, 140), (120, 80), (210, 80),
                 (210, 110), (240, 110), (240, 80), (270, 80), (270, 110), (300, 110), (300, 80),
                 (360, 80), (360, 110), (390, 110), (390, 1100), (0, 1100)],
                dy: dy
            ),
            with: .color(palette.stone)
        )

        // 深層岩
        context.fill(
            polygon(
                [(0, 690), (30, 690), (30, 660), (60, 660), (60, 690), (90, 690), (90, 660), (150, 660),
                 (150, 630), (240, 630), (240, 660), (270, 660), (270, 690), (330, 690), (330, 630),
                 (360, 630), (360, 690), (390, 690), (390, endless), (0, endless)],
                dy: dy
            ),
            with: .color(palette.deep)
        )

        // 洞窟 1（右。奥ほど暗い）と松明
        fillCave(
            context,
            polygon(
                [(360, 540), (240, 540), (240, 570), (210, 570), (210, 630), (240, 630), (240, 660),
                 (330, 660), (330, 630), (360, 630)],
                dy: dy
            ),
            center: CGPoint(x: 290, y: 600 + dy), radiusX: 95, radiusY: 80
        )
        drawTorch(in: context, dy: dy)

        // 洞窟 2（左。石と深層岩のあいだ）と鍾乳洞
        fillCave(
            context,
            polygon(
                [(20, 720), (200, 720), (200, 750), (230, 750), (230, 840), (200, 840), (200, 900),
                 (80, 900), (80, 870), (20, 870)],
                dy: dy
            ),
            center: CGPoint(x: 120, y: 810 + dy), radiusX: 125, radiusY: 105
        )
        context.fill(
            polygon([(20, 690), (200, 690), (200, 720), (20, 720)], dy: dy),
            with: .color(palette.dripTop)
        )
        let drips: [[(CGFloat, CGFloat)]] = [
            [(40, 720), (70, 720), (70, 760), (65, 760), (65, 800), (60, 800), (60, 830), (50, 830),
             (50, 800), (45, 800), (45, 760), (40, 760)],
            [(90, 720), (130, 720), (130, 745), (125, 745), (125, 770), (120, 770), (120, 790), (100, 790),
             (100, 770), (95, 770), (95, 745), (90, 745)],
            [(150, 720), (180, 720), (180, 750), (175, 750), (175, 790), (170, 790), (170, 820), (160, 820),
             (160, 790), (155, 790), (155, 750), (150, 750)],
        ]
        for drip in drips {
            context.fill(polygon(drip, dy: dy), with: .color(palette.drip))
        }

        // 岩盤
        context.fill(
            polygon(
                [(0, 1190), (30, 1190), (30, 1220), (60, 1220), (60, 1190), (90, 1190), (90, 1220),
                 (120, 1220), (120, 1160), (270, 1160), (270, 1190), (300, 1190), (300, 1220),
                 (360, 1220), (360, 1190), (390, 1190), (390, endless), (0, endless)],
                dy: dy
            ),
            with: .color(palette.bedrock)
        )

        // 奈落（ここから下は、どこまでも真っ暗）
        context.fill(
            polygon(
                [(0, 1260), (30, 1260), (30, 1230), (90, 1230), (90, 1260), (330, 1260), (330, 1230),
                 (360, 1230), (360, 1260), (390, 1260), (390, endless), (0, endless)],
                dy: dy
            ),
            with: .color(palette.void)
        )
    }

    // 洞窟の穴を、だ円のグラデーション（まん中ほど暗い）で塗る
    private func fillCave(
        _ context: GraphicsContext, _ shape: Path, center: CGPoint, radiusX: CGFloat, radiusY: CGFloat
    ) {
        var g = context
        g.clip(to: shape)
        g.translateBy(x: center.x, y: center.y)
        g.scaleBy(x: radiusX / radiusY, y: 1)  // 円を横にのばして、だ円にする
        g.fill(
            Path(CGRect(x: -400, y: -400, width: 800, height: 800)),
            with: .radialGradient(
                Gradient(colors: [palette.void, palette.cave]),
                center: .zero, startRadius: 0, endRadius: radiusY
            )
        )
    }

    // 松明：まわりの光がゆれて、炎がちらちらする
    private func drawTorch(in context: GraphicsContext, dy: CGFloat) {
        // 光
        var glow = context
        glow.opacity = 0.9 - 0.25 * wave(period: 1.6)
        glow.fill(
            Path(CGRect(x: 215, y: 560 + dy, width: 120, height: 120)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(hex: 0xFFAA3C, opacity: 0.55), location: 0),
                    .init(color: Color(hex: 0xFF8C28, opacity: 0.22), location: 0.45),
                    .init(color: Color(hex: 0xFF8C28, opacity: 0), location: 0.7),
                ]),
                center: CGPoint(x: 275, y: 620 + dy), startRadius: 0, endRadius: 85
            )
        )

        // 棒
        fillRect(context, 272, 624 + dy, 6, 36, Color(hex: 0x6B4423))

        // 炎（0.3 秒ごとに、明るさと高さを 3 段で切りかえる）
        let states: [(opacity: Double, scaleY: CGFloat)] = [(1, 1), (0.82, 0.9), (0.96, 1.05)]
        let state = states[min(Int(loop(period: 0.9) * 3), 2)]
        var flame = context
        flame.opacity = state.opacity
        flame.translateBy(x: 275, y: 626 + dy)  // 炎の下のまん中を中心に、縦にのび縮みさせる
        flame.scaleBy(x: 1, y: state.scaleY)
        flame.translateBy(x: -7, y: -20)
        fillRect(flame, 3, 0, 8, 6, Color(hex: 0xFFE066))
        fillRect(flame, 0, 6, 14, 8, Color(hex: 0xFF9A2E))
        fillRect(flame, 3, 14, 8, 6, Color(hex: 0xE8541E))
    }
}

#Preview {
    WorldDetailBackground(palette: .day, scrollOffset: 0)
        .ignoresSafeArea()
}
