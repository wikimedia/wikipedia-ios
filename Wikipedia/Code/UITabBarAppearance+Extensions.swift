import Foundation

@objc extension UITabBarAppearance {
    @objc static func appearanceForTheme(_ theme: Theme) -> UITabBarAppearance {
        let appearance = UITabBarAppearance()
        // CHANGE: Use fully transparent configuration for a flush look with underlying content.
        // Previous: configureWithTransparentBackground() + paperBackground color.
        appearance.configureWithTransparentBackground()
        // Remove solid fill so background shows through. If a tint is ever needed, reintroduce here.
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil
        appearance.shadowColor = .clear
        // If subtle divider needed later: appearance.shadowColor = theme.colors.border
        
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
