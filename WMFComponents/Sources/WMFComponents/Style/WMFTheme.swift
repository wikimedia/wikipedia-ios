import UIKit
import SwiftUI
import PassKit

public struct WMFTheme: Equatable {

	public let name: String
	public let userInterfaceStyle: UIUserInterfaceStyle
	public let keyboardAppearance: UIKeyboardAppearance
    public let text: UIColor
    public let secondaryText: UIColor
    public let link: UIColor
    public let accent: UIColor
    public let destructive: UIColor
    public let warning: UIColor
    public let border: UIColor
    public let newBorder: UIColor
    public let paperBackground: UIColor
    public let midBackground: UIColor
    public let baseBackground: UIColor
    public let popoverBackground: UIColor
    public let icon: UIColor
    public let iconBackground: UIColor
    public let accessoryBackground: UIColor
    public let inputAccessoryButtonTint: UIColor
    public let inputAccessoryButtonSelectedTint: UIColor
    public let inputAccessoryButtonSelectedBackgroundColor: UIColor
    public let keyboardBarSearchFieldBackground: UIColor
	public let diffCompareAccent: UIColor
    public let editorOrange: UIColor
    public let editorPurple: UIColor
    public let editorGreen: UIColor
    public let editorBlue: UIColor
    public let editorGray: UIColor
    public let editorMatchForeground: UIColor
    public let editorMatchBackground: UIColor
    public let editorSelectedMatchBackground: UIColor
    public let editorReplacedMatchBackground: UIColor
    public let editorButtonSelectedBackground: UIColor
    public let editorKeyboardShadow: UIColor
    public let chromeBackground: UIColor

	public var preferredColorScheme: ColorScheme {
		return (self == WMFTheme.light || self == WMFTheme.sepia) ? .light : .dark
	}
    
    public var applePayPaymentButtonStyle: PayWithApplePayButtonStyle {
        return (self == WMFTheme.light || self == WMFTheme.sepia) ? .black : .white
    }

	public static let light = WMFTheme(
        name: "Light",
		userInterfaceStyle: .light,
		keyboardAppearance: .light,
        text: WMFColor.gray700,
        secondaryText: WMFColor.gray500,
        link: WMFColor.blue600,
        accent: WMFColor.green600,
        destructive: WMFColor.red600,
        warning: WMFColor.orange600,
        border: WMFColor.gray400,
        newBorder: WMFColor.gray300,
        paperBackground: WMFColor.white,
        midBackground: WMFColor.gray100,
        baseBackground: WMFColor.gray200,
        popoverBackground: WMFColor.white,
        icon: WMFColor.gray300,
        iconBackground: WMFColor.gray500,
        accessoryBackground: WMFColor.white,
        inputAccessoryButtonTint: WMFColor.gray600,
        inputAccessoryButtonSelectedTint: WMFColor.gray700,
        inputAccessoryButtonSelectedBackgroundColor: WMFColor.gray200,
        keyboardBarSearchFieldBackground: WMFColor.gray200,
		diffCompareAccent: WMFColor.orange600,
        editorOrange: WMFColor.orange600,
        editorPurple: WMFColor.purple600,
        editorGreen: WMFColor.green600,
        editorBlue: WMFColor.blue600,
        editorGray: WMFColor.gray500,
        editorMatchForeground: .black,
        editorMatchBackground: WMFColor.lightMatchBackground,
        editorSelectedMatchBackground: WMFColor.yellow600,
        editorReplacedMatchBackground: WMFColor.matchReplacedBackground,
        editorButtonSelectedBackground: WMFColor.gray200,
        editorKeyboardShadow: WMFColor.gray200,
        chromeBackground: WMFColor.white
	)
    
    public static let sepia = WMFTheme(
        name: "Sepia",
		userInterfaceStyle: .light,
        keyboardAppearance: .light,
        text: WMFColor.gray700,
        secondaryText: WMFColor.taupe600,
        link: WMFColor.blue600,
        accent: WMFColor.green600,
        destructive: WMFColor.red700,
        warning: WMFColor.orange600,
        border: WMFColor.taupe200,
        newBorder: WMFColor.taupe200,
        paperBackground: WMFColor.beige100,
        midBackground: WMFColor.beige300,
        baseBackground: WMFColor.beige400,
        popoverBackground: WMFColor.beige100,
        icon: WMFColor.taupe600,
        iconBackground: WMFColor.beige400,
        accessoryBackground: WMFColor.beige300,
        inputAccessoryButtonTint: WMFColor.gray600,
        inputAccessoryButtonSelectedTint: WMFColor.gray700,
        inputAccessoryButtonSelectedBackgroundColor: WMFColor.beige400,
        keyboardBarSearchFieldBackground: WMFColor.gray200,
		diffCompareAccent: WMFColor.orange600,
        editorOrange: WMFColor.orange600,
        editorPurple: WMFColor.purple600,
        editorGreen: WMFColor.green600,
        editorBlue: WMFColor.blue600,
        editorGray: WMFColor.taupe600,
        editorMatchForeground: .black,
        editorMatchBackground: WMFColor.lightMatchBackground,
        editorSelectedMatchBackground: WMFColor.yellow600,
        editorReplacedMatchBackground: WMFColor.matchReplacedBackground,
        editorButtonSelectedBackground: WMFColor.beige400,
        editorKeyboardShadow: WMFColor.taupe200,
        chromeBackground: WMFColor.beige100
    )

	public static let dark = WMFTheme(
		name: "Dark",
		userInterfaceStyle: .dark,
		keyboardAppearance: .dark,
        text: WMFColor.gray100,
        secondaryText: WMFColor.gray300,
        link: WMFColor.blue300,
        accent: WMFColor.green600,
        destructive: WMFColor.red600,
        warning: WMFColor.yellow600,
        border: WMFColor.gray650,
        newBorder: WMFColor.gray500,
        paperBackground: WMFColor.gray675,
        midBackground: WMFColor.gray700,
        baseBackground: WMFColor.gray800,
        popoverBackground: WMFColor.gray800,
        icon: WMFColor.gray300,
        iconBackground: WMFColor.gray675,
        accessoryBackground: WMFColor.gray700,
        inputAccessoryButtonTint: WMFColor.gray100,
        inputAccessoryButtonSelectedTint: WMFColor.gray100,
        inputAccessoryButtonSelectedBackgroundColor: WMFColor.gray800,
        keyboardBarSearchFieldBackground: WMFColor.gray650,
		diffCompareAccent: WMFColor.orange600,
        editorOrange: WMFColor.yellow600,
        editorPurple: WMFColor.red100,
        editorGreen: WMFColor.green600,
        editorBlue: WMFColor.blue300,
        editorGray: WMFColor.gray300,
        editorMatchForeground: .black,
        editorMatchBackground: WMFColor.darkMatchBackground,
        editorSelectedMatchBackground: WMFColor.yellow600,
        editorReplacedMatchBackground: WMFColor.matchReplacedBackground,
        editorButtonSelectedBackground: WMFColor.gray600,
        editorKeyboardShadow: WMFColor.gray800,
        chromeBackground: WMFColor.gray650
	)

	public static let black = WMFTheme(
		name: "Black",
		userInterfaceStyle: .dark,
		keyboardAppearance: .dark,
        text: WMFColor.gray100,
        secondaryText: WMFColor.gray300,
        link: WMFColor.blue300,
        accent: WMFColor.green600,
        destructive: WMFColor.red600,
        warning: WMFColor.yellow600,
        border: WMFColor.gray675,
        newBorder: WMFColor.gray500,
        paperBackground: WMFColor.black,
        midBackground: WMFColor.gray700,
        baseBackground: WMFColor.gray800,
        popoverBackground: WMFColor.gray700,
        icon: WMFColor.gray300,
        iconBackground: WMFColor.gray675,
        accessoryBackground: WMFColor.gray700,
        inputAccessoryButtonTint: WMFColor.gray100,
        inputAccessoryButtonSelectedTint: WMFColor.gray100,
        inputAccessoryButtonSelectedBackgroundColor: WMFColor.gray800,
        keyboardBarSearchFieldBackground: WMFColor.gray650,
		diffCompareAccent: WMFColor.orange600,
        editorOrange: WMFColor.yellow600,
        editorPurple: WMFColor.red100,
        editorGreen: WMFColor.green600,
        editorBlue: WMFColor.blue300,
        editorGray: WMFColor.gray300,
        editorMatchForeground: .black,
        editorMatchBackground: WMFColor.darkMatchBackground,
        editorSelectedMatchBackground: WMFColor.yellow600,
        editorReplacedMatchBackground: WMFColor.matchReplacedBackground,
        editorButtonSelectedBackground: WMFColor.gray600,
        editorKeyboardShadow: WMFColor.gray700,
        chromeBackground: WMFColor.gray650
	)

}
