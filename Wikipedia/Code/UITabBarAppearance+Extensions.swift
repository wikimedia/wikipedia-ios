import Foundation

@objc extension UITabBarAppearance {
    @objc static func appearanceForTheme(_ theme: Theme) -> UITabBarAppearance {
        let appearance = UITabBarAppearance()
        if #available(iOS 26.0, *) {
            // Liquid Glass: transparent background and no divider.
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.backgroundEffect = nil
            appearance.shadowColor = .clear
            // If subtle divider needed later: appearance.shadowColor = theme.colors.border
        } else {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = theme.colors.chromeBackground
        }
        
        let itemAppearance = UITabBarItemAppearance()
        let normalStateAppearance = itemAppearance.normal
        normalStateAppearance.titleTextAttributes = theme.tabBarTitleTextAttributes
        normalStateAppearance.badgeTextAttributes = theme.tabBarItemBadgeTextAttributes
        normalStateAppearance.badgeBackgroundColor = theme.colors.accent
        normalStateAppearance.iconColor = theme.colors.unselected
        let selectedStateAppearance = itemAppearance.selected
        selectedStateAppearance.titleTextAttributes = theme.tabBarSelectedTitleTextAttributes
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        return appearance
    }
}
