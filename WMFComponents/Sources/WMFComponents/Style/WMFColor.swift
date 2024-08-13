import UIKit
import SwiftUI

/// Color definitions from Wikimedia Style Guide
public enum WMFColor {

    public static let black = UIColor.black
    public static let white = UIColor.white

    public static let gray800 = UIColor(0x101418)
    public static let gray700 = UIColor(0x202122)
    public static let gray675 = UIColor(0x27292D)
    public static let gray650 = UIColor(0x2E3136)
    public static let gray600 = UIColor(0x54595D)
    public static let gray500 = UIColor(0x72777D)
    public static let gray400 = UIColor(0xA2A9B1)
    public static let gray300 = UIColor(0xC8CCD1)
    public static let gray200 = UIColor(0xEAECF0)
    public static let gray150 = UIColor(0xEEF2FB)
    public static let gray100 = UIColor(0xF8F9FA)
    public static let blue700 = UIColor(0x2A4B8D)
    public static let blue600 = UIColor(0x3366CC)
    public static let blue300 = UIColor(0x6699FF)
    public static let blue100 = UIColor(0xEAF3FF)
    public static let red700 = UIColor(0xB32424)
    public static let red600 = UIColor(0xDD3333)
    public static let red100 = UIColor(0xFEE7E6)
    public static let green600 = UIColor(0x00AF89)
    public static let green100 = UIColor(0xD5FDF4)
    public static let yellow600 = UIColor(0xFFCC33)
    public static let beige400 = UIColor(0xE1DAD1)
    public static let beige300 = UIColor(0xF0E6D6)
    public static let beige100 = UIColor(0xF8F1E3)
    public static let taupe600 = UIColor(0x646059)
    public static let taupe200 = UIColor(0xCBC8C1)
    public static let purple600 = UIColor(0x6b4ba1)
    public static let orange600 = UIColor(0xFF9500)

    public static let darkSearchFieldBackground = UIColor(0x8E8E93, alpha: 0.12)
    public static let lightSearchFieldBackground = UIColor(0xFFFFFF, alpha: 0.15)
    public static let lightMatchBackground = WMFColor.yellow600.withAlphaComponent(0.3)
    public static let darkMatchBackground = UIColor(0xF7D779).withAlphaComponent(0.7)
    public static let matchReplacedBackground = UIColor(0xD0E4fC)

}
