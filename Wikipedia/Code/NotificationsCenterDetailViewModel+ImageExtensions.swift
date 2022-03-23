import Foundation

extension NotificationsCenterDetailViewModel {
    var headerImageName: String {
        return commonViewModel.notification.type.imageName
    }
    
    func headerImageBackgroundColorWithTheme(_ theme: Theme) -> UIColor {
        return commonViewModel.notification.type.imageBackgroundColorWithTheme(theme)
    }
}
