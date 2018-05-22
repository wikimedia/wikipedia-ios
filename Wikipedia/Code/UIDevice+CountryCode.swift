extension UIDevice {
    public static var countryCode: String? {
        return (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as? String
    }
}
