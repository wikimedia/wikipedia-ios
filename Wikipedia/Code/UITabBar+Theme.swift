import WMF

extension UITabBar: Themeable {
    public func apply(theme: Theme) {
        barTintColor = theme.colors.chromeBackground
        unselectedItemTintColor = theme.colors.unselected
        isTranslucent = false
    }
}

extension UITabBarItem: Themeable {
    public func apply(theme: Theme) {
        badgeColor = theme.colors.accent
        setBadgeTextAttributes(theme.tabBarItemBadgeTextAttributes, for: .normal)
        setTitleTextAttributes(theme.tabBarTitleTextAttributes, for: .normal)
        setTitleTextAttributes(theme.tabBarSelectedTitleTextAttributes, for: .selected)
    }
}
