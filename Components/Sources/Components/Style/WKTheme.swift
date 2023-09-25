import UIKit

public struct WKTheme: Equatable {

	public let name: String
	public let userInterfaceStyle: UIUserInterfaceStyle
	public let keyboardAppearance: UIKeyboardAppearance
    public let text: UIColor
    public let secondaryText: UIColor
    public let link: UIColor
    public let accent: UIColor
    public let destructive: UIColor
    public let border: UIColor
    public let paperBackground: UIColor
    public let baseBackground: UIColor
    public let icon: UIColor
    public let iconBackground: UIColor
    public let accessoryBackground: UIColor
    public let inputAccessoryButtonTint: UIColor
    public let inputAccessoryButtonSelectedTint: UIColor
    public let inputAccessoryButtonSelectedBackgroundColor: UIColor
    public let keyboardBarSearchFieldBackground: UIColor
	public let diffCompareAccent: UIColor

	public static let light = WKTheme(
        name: "Light",
		userInterfaceStyle: .light,
		keyboardAppearance: .light,
        text: WKColor.gray700,
        secondaryText: WKColor.gray500,
        link: WKColor.blue600,
        accent: WKColor.green600,
        destructive: WKColor.red600,
        border: WKColor.gray400,
        paperBackground: WKColor.white,
        baseBackground: WKColor.gray200,
        icon: WKColor.white,
        iconBackground: WKColor.gray500,
        accessoryBackground: WKColor.white,
        inputAccessoryButtonTint: WKColor.gray600,
        inputAccessoryButtonSelectedTint: WKColor.gray700,
        inputAccessoryButtonSelectedBackgroundColor: WKColor.gray200,
        keyboardBarSearchFieldBackground: WKColor.gray200,
		diffCompareAccent: WKColor.orange600
	)
    
    public static let sepia = WKTheme(
        name: "Sepia",
		userInterfaceStyle: .light,
		keyboardAppearance: .light,
        text: WKColor.gray700,
        secondaryText: WKColor.taupe600,
        link: WKColor.blue600,
        accent: WKColor.green600,
        destructive: WKColor.red700,
        border: WKColor.taupe200,
        paperBackground: WKColor.beige100,
        baseBackground: WKColor.beige400,
        icon: WKColor.taupe600,
        iconBackground: WKColor.beige400,
        accessoryBackground: WKColor.beige300,
        inputAccessoryButtonTint: WKColor.gray600,
        inputAccessoryButtonSelectedTint: WKColor.gray700,
        inputAccessoryButtonSelectedBackgroundColor: WKColor.beige400,
        keyboardBarSearchFieldBackground: WKColor.gray200,
		diffCompareAccent: WKColor.orange600
    )

	public static let dark = WKTheme(
		name: "Dark",
		userInterfaceStyle: .dark,
		keyboardAppearance: .dark,
        text: WKColor.gray100,
        secondaryText: WKColor.gray300,
        link: WKColor.blue300,
        accent: WKColor.green600,
        destructive: WKColor.red600,
        border: WKColor.gray650,
        paperBackground: WKColor.gray675,
        baseBackground: WKColor.gray800,
        icon: WKColor.gray300,
        iconBackground: WKColor.gray675,
        accessoryBackground: WKColor.gray700,
        inputAccessoryButtonTint: WKColor.gray100,
        inputAccessoryButtonSelectedTint: WKColor.gray100,
        inputAccessoryButtonSelectedBackgroundColor: WKColor.gray800,
        keyboardBarSearchFieldBackground: WKColor.gray650,
		diffCompareAccent: WKColor.orange600
	)

	public static let black = WKTheme(
		name: "Black",
		userInterfaceStyle: .dark,
		keyboardAppearance: .dark,
        text: WKColor.gray100,
        secondaryText: WKColor.gray300,
        link: WKColor.blue300,
        accent: WKColor.green600,
        destructive: WKColor.red600,
        border: WKColor.gray675,
        paperBackground: WKColor.black,
        baseBackground: WKColor.gray800,
        icon: WKColor.gray300,
        iconBackground: WKColor.gray675,
        accessoryBackground: WKColor.gray700,
        inputAccessoryButtonTint: WKColor.gray100,
        inputAccessoryButtonSelectedTint: WKColor.gray100,
        inputAccessoryButtonSelectedBackgroundColor: WKColor.gray800,
        keyboardBarSearchFieldBackground: WKColor.gray650,
		diffCompareAccent: WKColor.orange600
	)

}
