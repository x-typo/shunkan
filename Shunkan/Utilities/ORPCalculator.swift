import Foundation

enum ORPCalculator {
    static func optimalIndex(for word: String) -> Int {
        let length = word.count
        switch length {
        case 0...1: return 0
        case 2...5: return 1
        case 6...9: return 2
        case 10...13: return 3
        default: return 4
        }
    }
}
