// SensorResponseTemplates.swift — 応答テンプレート
// 3キャラクター × 2パターン × 受容3種 + 深層問いかけ

import Foundation

enum ReceptionType {
    case empathy        // 共感
    case appreciation   // 称賛
    case affirmation    // 肯定
}

struct SensorResponseTemplates {

    static func reception(pattern: SensorPattern, character: CharacterType, type: ReceptionType) -> String {
        let templates = receptionTemplates(pattern: pattern, character: character, type: type)
        return templates.randomElement() ?? "そうか。"
    }

    static func deepQuestion(pattern: SensorPattern, character: CharacterType) -> String {
        let templates = deepQuestionTemplates(pattern: pattern, character: character)
        return templates.randomElement() ?? "もう少し聞かせてくれるか。"
    }

    // MARK: - Reception Templates

    private static func receptionTemplates(pattern: SensorPattern, character: CharacterType, type: ReceptionType) -> [String] {
        switch (pattern, character, type) {
        case (.factVsAssumption, .master, .empathy):
            return ["そう感じてたんだな。", "そう思えてしまう状況があったんだな。", "それはしんどいな。"]
        case (.factVsAssumption, .senpai, .empathy):
            return ["そっか、そういう気持ちになったのか。", "まあ、そう見えるよな。", "うん、そう感じるよな。"]
        case (.factVsAssumption, .friend, .empathy):
            return ["ええ、それしんどいじゃん。", "そう感じちゃうよね。", "それはつらいよ。"]
        case (.taskOverload, .master, .appreciation):
            return ["よく気がつく人なんだな。", "抱えてきたんだな。", "それはしんどいところまで来てるな。"]
        case (.taskOverload, .senpai, .appreciation):
            return ["まあ、お前は気がつきすぎるんだよ。", "よく引き受けてきたな。", "しんどかったろ。"]
        case (.taskOverload, .friend, .appreciation):
            return ["もう、優しすぎだよ。", "よくそこまでやってきたよ。", "それ、全部抱えてたの？"]
        default:
            return fallbackReception(character: character)
        }
    }

    private static func fallbackReception(character: CharacterType) -> [String] {
        switch character {
        case .master: return ["そうか。", "うん。", "なるほどな。"]
        case .senpai: return ["そっか。", "ふむ。", "まあな。"]
        case .friend: return ["そっかー。", "うんうん。", "なるほど！"]
        }
    }

    // MARK: - Deep Question Templates

    private static func deepQuestionTemplates(pattern: SensorPattern, character: CharacterType) -> [String] {
        switch (pattern, character) {
        case (.factVsAssumption, .master):
            return [
                "そう感じた出来事、具体的には何があったんだ？",
                "その人が実際にそう言ったのか、雰囲気でそう感じたのか。",
                "何かきっかけがあったか？"
            ]
        case (.factVsAssumption, .senpai):
            return [
                "実際にそう言われたのか、それともそう感じたのか？",
                "何があってそう思ったんだ？",
                "具体的にどんな場面でそう感じた？"
            ]
        case (.factVsAssumption, .friend):
            return [
                "実際に何か言われたの？それとも雰囲気？",
                "どんなことがあってそう思ったの？",
                "具体的に教えてよ。"
            ]
        case (.taskOverload, .master):
            return [
                "それ、本来は誰がやることだったんだろうな。",
                "引き受けたとき、自分の気持ちはどうだった？",
                "なぜ自分がやらなきゃと思ったんだ？"
            ]
        case (.taskOverload, .senpai):
            return [
                "それ、お前がやらなきゃいけないことだったのか？",
                "引き受けたとき、どんな気持ちだった？",
                "断れなかったのか？"
            ]
        case (.taskOverload, .friend):
            return [
                "それって、あなたがやらなきゃいけないことだった？",
                "引き受けたとき、どんな気持ちだったの？",
                "なんで自分がって思ったの？"
            ]
        case (.none, _):
            return generalQuestion(character: character)
        }
    }

    private static func generalQuestion(character: CharacterType) -> [String] {
        switch character {
        case .master: return ["もう少し聞かせてくれるか。", "どんなことがあったんだ？"]
        case .senpai: return ["もう少し詳しく教えてくれ。", "何があったんだ？"]
        case .friend: return ["もう少し話して？", "どういうこと？"]
        }
    }
}
