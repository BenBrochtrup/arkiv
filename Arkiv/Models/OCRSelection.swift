import CoreGraphics
import Foundation

struct OCRSelection: Equatable, Sendable {
    var blockIDs: Set<UUID> = []
    var region: CGRect?
}
