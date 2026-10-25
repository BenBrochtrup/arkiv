import SwiftUI
import UIKit

struct ImagePreview: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 420)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4, y: 2)
            .accessibilityLabel("Selected screenshot preview")
    }
}
