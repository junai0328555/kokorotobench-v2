// CharacterAvatarView.swift
// こころとベンチ — キャラクター線画アバター

import SwiftUI

// MARK: - CharacterType カラーテーマ拡張

extension CharacterType {
    /// アバター背景の淡い円色
    var avatarBgColor: Color {
        switch self {
        case .master: return Color(red: 0.94, green: 0.90, blue: 0.84)  // 温かい砂色
        case .senpai: return Color(red: 0.87, green: 0.92, blue: 0.97)  // 霞のような水色
        case .friend: return Color(red: 0.93, green: 0.88, blue: 0.97)  // 柔らかいラベンダー
        }
    }

    /// 線画のインク色
    var avatarInkColor: Color {
        switch self {
        case .master: return Color(red: 0.27, green: 0.19, blue: 0.11)  // ウォールナット
        case .senpai: return Color(red: 0.16, green: 0.27, blue: 0.43)  // ネイビー
        case .friend: return Color(red: 0.37, green: 0.23, blue: 0.52)  // プラム
        }
    }

    /// UIアクセント・バブル塗り色
    var themeColor: Color {
        switch self {
        case .master: return Color(red: 0.48, green: 0.34, blue: 0.22)  // ウイスキーブラウン
        case .senpai: return Color(red: 0.25, green: 0.43, blue: 0.63)  // デニムブルー
        case .friend: return Color(red: 0.50, green: 0.34, blue: 0.67)  // バイオレット
        }
    }
}

// MARK: - CharacterAvatarView

/// 線画スタイルの人型キャラクターアバター。複数サイズで使用可能。
struct CharacterAvatarView: View {
    let character: CharacterType
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(character.avatarBgColor)
                .frame(width: size, height: size)

            Canvas { ctx, sz in
                drawFigure(ctx: ctx, size: sz)
            }
            .frame(width: size * 0.70, height: size * 0.70)
            .foregroundStyle(character.avatarInkColor)
        }
        .frame(width: size, height: size)
    }

    // MARK: - メイン描画

    private func drawFigure(ctx: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let lw = max(1.3, w * 0.056)   // サイズに比例した線幅
        let cx = w / 2

        // 頭の比率
        let headR    = w * 0.232
        let headTopY = h * 0.04
        let headCtrY = headTopY + headR
        let headBotY = headTopY + headR * 2

        // 体の比率
        let shoulderY = headBotY + h * 0.065
        let hipY      = shoulderY + h * 0.26

        // ── 頭 ──
        var headPath = Path()
        headPath.addEllipse(in: CGRect(
            x: cx - headR, y: headTopY,
            width: headR * 2, height: headR * 2
        ))
        ctx.stroke(headPath, with: .foreground,
                   style: StrokeStyle(lineWidth: lw, lineCap: .round))

        // ── 体幹 ──
        var spine = Path()
        spine.move(to: CGPoint(x: cx, y: headBotY))
        spine.addLine(to: CGPoint(x: cx, y: hipY))
        ctx.stroke(spine, with: .foreground,
                   style: StrokeStyle(lineWidth: lw, lineCap: .round))

        // ── 脚 ──
        var legs = Path()
        legs.move(to: CGPoint(x: cx, y: hipY))
        legs.addLine(to: CGPoint(x: cx - w * 0.17, y: h * 0.97))
        legs.move(to: CGPoint(x: cx, y: hipY))
        legs.addLine(to: CGPoint(x: cx + w * 0.17, y: h * 0.97))
        ctx.stroke(legs, with: .foreground,
                   style: StrokeStyle(lineWidth: lw * 0.86, lineCap: .round))

        // ── 腕（キャラ別ポーズ）──
        drawArms(ctx: ctx, w: w, h: h, cx: cx, shoulderY: shoulderY, lw: lw)

        // ── 髪・アクセサリー ──
        drawDetails(ctx: ctx, w: w, h: h, cx: cx,
                    headR: headR, headTopY: headTopY,
                    headCtrY: headCtrY, headBotY: headBotY,
                    shoulderY: shoulderY, lw: lw)
    }

    // MARK: - 腕

    private func drawArms(ctx: GraphicsContext, w: CGFloat, h: CGFloat,
                          cx: CGFloat, shoulderY: CGFloat, lw: CGFloat) {
        let shY   = shoulderY + h * 0.03
        let style = StrokeStyle(lineWidth: lw * 0.86, lineCap: .round)
        var arms  = Path()

        switch character {
        case .master:
            // 少し整った、フォーマルなポーズ
            arms.move(to: CGPoint(x: cx, y: shY))
            arms.addLine(to: CGPoint(x: cx - w * 0.27, y: shY + h * 0.20))
            arms.move(to: CGPoint(x: cx, y: shY))
            arms.addLine(to: CGPoint(x: cx + w * 0.27, y: shY + h * 0.20))

        case .senpai:
            // 片方がカジュアルにやや外側（リラックス感）
            arms.move(to: CGPoint(x: cx, y: shY))
            arms.addLine(to: CGPoint(x: cx - w * 0.29, y: shY + h * 0.22))
            arms.move(to: CGPoint(x: cx, y: shY))
            arms.addQuadCurve(
                to: CGPoint(x: cx + w * 0.28, y: shY + h * 0.17),
                control: CGPoint(x: cx + w * 0.18, y: shY + h * 0.04)
            )

        case .friend:
            // 片手を少し上げた元気なポーズ
            arms.move(to: CGPoint(x: cx, y: shY))
            arms.addLine(to: CGPoint(x: cx - w * 0.27, y: shY + h * 0.21))
            arms.move(to: CGPoint(x: cx, y: shY))
            arms.addLine(to: CGPoint(x: cx + w * 0.25, y: shY - h * 0.05))
        }

        ctx.stroke(arms, with: .foreground, style: style)
    }

    // MARK: - 髪・アクセサリー

    private func drawDetails(ctx: GraphicsContext,
                             w: CGFloat, h: CGFloat, cx: CGFloat,
                             headR: CGFloat, headTopY: CGFloat,
                             headCtrY: CGFloat, headBotY: CGFloat,
                             shoulderY: CGFloat, lw: CGFloat) {
        let hairLW   = lw * 1.35
        let detailLW = lw * 0.72

        switch character {

        // ─────────────────────────────────────
        case .master:   // バーのマスター: 短髪 + 蝶ネクタイ
        // ─────────────────────────────────────
            var hair = Path()
            hair.addArc(
                center: CGPoint(x: cx, y: headCtrY * 0.88),
                radius: headR * 0.97,
                startAngle: .degrees(208), endAngle: .degrees(332), clockwise: false
            )
            ctx.stroke(hair, with: .foreground,
                       style: StrokeStyle(lineWidth: hairLW, lineCap: .round))

            // 蝶ネクタイ（菱形）
            let btY = headBotY + (shoulderY - headBotY) * 0.50
            var bt  = Path()
            bt.move(to: CGPoint(x: cx - w * 0.09, y: btY))
            bt.addLine(to: CGPoint(x: cx, y: btY - w * 0.040))
            bt.addLine(to: CGPoint(x: cx + w * 0.09, y: btY))
            bt.addLine(to: CGPoint(x: cx, y: btY + w * 0.040))
            bt.closeSubpath()
            ctx.stroke(bt, with: .foreground,
                       style: StrokeStyle(lineWidth: detailLW,
                                          lineCap: .round, lineJoin: .round))

        // ─────────────────────────────────────
        case .senpai:   // 先輩: やや乱れた中髪 + Vカラー
        // ─────────────────────────────────────
            var hair = Path()
            hair.addArc(
                center: CGPoint(x: cx - w * 0.02, y: headCtrY * 0.84),
                radius: headR * 0.97,
                startAngle: .degrees(197), endAngle: .degrees(343), clockwise: false
            )
            // 横に流れる一房
            hair.move(to: CGPoint(x: cx + headR * 0.82, y: headTopY + headR * 0.55))
            hair.addQuadCurve(
                to: CGPoint(x: cx + headR * 0.62, y: headBotY - headR * 0.18),
                control: CGPoint(x: cx + headR * 1.30, y: headTopY + headR * 1.08)
            )
            ctx.stroke(hair, with: .foreground,
                       style: StrokeStyle(lineWidth: hairLW, lineCap: .round))

            // Vカラー（開襟シャツ）
            let colY = headBotY + (shoulderY - headBotY) * 0.38
            var collar = Path()
            collar.move(to: CGPoint(x: cx - w * 0.08, y: headBotY + h * 0.01))
            collar.addLine(to: CGPoint(x: cx, y: colY))
            collar.move(to: CGPoint(x: cx + w * 0.08, y: headBotY + h * 0.01))
            collar.addLine(to: CGPoint(x: cx, y: colY))
            ctx.stroke(collar, with: .foreground,
                       style: StrokeStyle(lineWidth: detailLW, lineCap: .round))

        // ─────────────────────────────────────
        case .friend:   // 友達: 長い流れ髪 + 笑顔
        // ─────────────────────────────────────
            var hair = Path()
            // 上部アーク
            hair.addArc(
                center: CGPoint(x: cx, y: headCtrY * 0.87),
                radius: headR * 0.97,
                startAngle: .degrees(186), endAngle: .degrees(354), clockwise: false
            )
            // 左側に流れる髪
            hair.move(to: CGPoint(x: cx - headR * 0.88, y: headTopY + headR * 0.78))
            hair.addQuadCurve(
                to: CGPoint(x: cx - headR * 0.74, y: headBotY + headR * 0.52),
                control: CGPoint(x: cx - headR * 1.38, y: headTopY + headR * 1.58)
            )
            // 右側に流れる髪
            hair.move(to: CGPoint(x: cx + headR * 0.88, y: headTopY + headR * 0.78))
            hair.addQuadCurve(
                to: CGPoint(x: cx + headR * 0.74, y: headBotY + headR * 0.52),
                control: CGPoint(x: cx + headR * 1.38, y: headTopY + headR * 1.58)
            )
            ctx.stroke(hair, with: .foreground,
                       style: StrokeStyle(lineWidth: hairLW, lineCap: .round))

            // 笑顔
            var smile = Path()
            smile.addArc(
                center: CGPoint(x: cx, y: headTopY + headR * 1.40),
                radius: headR * 0.27,
                startAngle: .degrees(18), endAngle: .degrees(162), clockwise: false
            )
            ctx.stroke(smile, with: .foreground,
                       style: StrokeStyle(lineWidth: detailLW, lineCap: .round))
        }
    }
}

// MARK: - Preview

#Preview("アバター 各サイズ") {
    VStack(spacing: 24) {
        HStack(spacing: 24) {
            CharacterAvatarView(character: .master, size: 80)
            CharacterAvatarView(character: .senpai, size: 80)
            CharacterAvatarView(character: .friend, size: 80)
        }
        HStack(spacing: 16) {
            CharacterAvatarView(character: .master, size: 44)
            CharacterAvatarView(character: .senpai, size: 44)
            CharacterAvatarView(character: .friend, size: 44)
        }
        HStack(spacing: 12) {
            CharacterAvatarView(character: .master, size: 34)
            CharacterAvatarView(character: .senpai, size: 34)
            CharacterAvatarView(character: .friend, size: 34)
        }
    }
    .padding(32)
    .background(Color(red: 0.98, green: 0.97, blue: 0.96))
}
