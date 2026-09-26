//
//  AppIcon.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 27/9/26.
//
import SwiftUI

// 1. Extend Bundle to extract the app icon's filename from AppIcon.Icon
extension Bundle {
    var appIconName: String? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconFileName = iconFiles.last else {
            return nil
        }
        return iconFileName
    }
}

    // 2. Display the icon using a conditional Image view
struct AppIconView: View {
    var body: some View {
        if let iconName = Bundle.main.appIconName,
           let uiImage = UIImage(named: iconName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .circular))
        } else {
                // Fallback placeholder in case the icon can't be fetched
            Image(systemName: "app.square.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)
        }
    }
}

