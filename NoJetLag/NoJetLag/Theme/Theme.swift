import SwiftUI
import UIKit

// =====================================================================
// NoJetLag Theme — see DESIGN.md in repo root.
// Direction: industrial / pilot-watch. Dark mode primary.
// All UI code reads from these tokens. Do not hardcode hex / spacing.
// =====================================================================

// MARK: - Color tokens (cockpit-night dark, warm-paper light)

extension Color {
    /// Dark+light dynamic color built from two hex strings.
    fileprivate static func dyn(_ darkHex: UInt32, _ lightHex: UInt32) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: darkHex)
                : UIColor(hex: lightHex)
        })
    }

    // Surfaces
    static let bg0:          Color = dyn(0x0E1116, 0xF4F1EA) // app background
    static let bg1:          Color = dyn(0x161A22, 0xFFFFFF) // elevated (cards, sheets)
    static let bg2:          Color = dyn(0x1D222C, 0xEFEAE0) // inset / inactive controls
    static let stroke:       Color = dyn(0x2A2F36, 0xE0DCD2) // borders, dividers
    static let strokeStrong: Color = dyn(0x3A4049, 0xC8C2B5) // focused / strong borders

    // Text
    static let textHi:       Color = dyn(0xECECEC, 0x1C1C1E)
    static let textMid:      Color = dyn(0xB7BCC4, 0x4A4F58)
    static let textLo:       Color = dyn(0x8A8F98, 0x6E737B)

    // Single accent
    static let amber:        Color = Color(uiColor: UIColor(hex: 0xFFB000))
    static let amberDim:     Color = Color(uiColor: UIColor(hex: 0xB07700))

    // Semantics
    static let advisoryRed:   Color = Color(uiColor: UIColor(hex: 0xE5484D)) // avoid / warning
    static let sleepIndigo:   Color = Color(uiColor: UIColor(hex: 0x5E6AD2)) // sleep events
    static let caffeineGreen: Color = Color(uiColor: UIColor(hex: 0x46A758)) // caffeine ok / positive
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red:   CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8)  & 0xFF) / 255,
            blue:  CGFloat( hex        & 0xFF) / 255,
            alpha: alpha
        )
    }
}

// MARK: - Spacing scale (4pt base)

enum Spacing {
    static let xs2: CGFloat = 2
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl:CGFloat = 48
}

// MARK: - Radii (small — instrument-panel, not soft consumer)

enum Radius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
}

// MARK: - Typography
//
// Strategy: use system font with the right weights, design, and width so the
// app feels "instrument" out of the box. If IBM Plex .ttf files are bundled
// later under Resources/Fonts/ and registered in Info.plist (UIAppFonts),
// flip `usePlex` to true and the helpers will use them automatically.
//
// To bundle IBM Plex:
//   1. Download from github.com/IBM/plex (SIL OFL, free)
//   2. Drag IBMPlexSansCondensed-{Regular,Medium,SemiBold}.ttf,
//      IBMPlexSans-{Regular,Medium,SemiBold}.ttf,
//      IBMPlexMono-{Regular,Medium}.ttf into Xcode (NoJetLag target)
//   3. Add UIAppFonts array to Info.plist with each filename
//   4. Set Typography.usePlex = true below

enum Typography {
    /// Set to true after bundling IBM Plex fonts.
    static let usePlex: Bool = false

    // Internal: pick the right family name when bundled.
    private static func plexCondensed(_ weight: Weight) -> String {
        switch weight {
        case .regular:  return "IBMPlexSansCondensed"
        case .medium:   return "IBMPlexSansCondensed-Medium"
        case .semibold: return "IBMPlexSansCondensed-SemiBold"
        }
    }
    private static func plexSans(_ weight: Weight) -> String {
        switch weight {
        case .regular:  return "IBMPlexSans"
        case .medium:   return "IBMPlexSans-Medium"
        case .semibold: return "IBMPlexSans-SemiBold"
        }
    }
    private static func plexMono(_ weight: Weight) -> String {
        switch weight {
        case .regular:  return "IBMPlexMono"
        case .medium:   return "IBMPlexMono-Medium"
        case .semibold: return "IBMPlexMono-SemiBold"
        }
    }

    enum Weight { case regular, medium, semibold
        var system: Font.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            }
        }
    }

    // MARK: Display (condensed for hero numbers, big advice text)

    static func display(_ size: CGFloat, weight: Weight = .semibold) -> Font {
        if usePlex {
            return .custom(plexCondensed(weight), size: size)
        } else {
            return .system(size: size, weight: weight.system, design: .default)
                .width(.condensed)
        }
    }

    // MARK: Body (paragraphs, secondary text)

    static func body(_ size: CGFloat = 15, weight: Weight = .regular) -> Font {
        if usePlex {
            return .custom(plexSans(weight), size: size)
        } else {
            return .system(size: size, weight: weight.system, design: .default)
        }
    }

    // MARK: Mono (times, codes, countdowns, badges)

    static func mono(_ size: CGFloat, weight: Weight = .medium) -> Font {
        if usePlex {
            return .custom(plexMono(weight), size: size)
        } else {
            return .system(size: size, weight: weight.system, design: .monospaced)
        }
    }
}

// MARK: - Tracked label (uppercase mono with letter-spacing)

extension View {
    /// Apply uppercase + tracked spacing for status tags / section headers.
    func trackedUppercase(_ tracking: CGFloat = 1.2) -> some View {
        self
            .textCase(.uppercase)
            .tracking(tracking)
    }
}
