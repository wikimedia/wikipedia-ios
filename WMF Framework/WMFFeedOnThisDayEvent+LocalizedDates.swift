extension WMFFeedOnThisDayEvent {
    // Returns year string - i.e. '1000' (for AD) or '200 BC'. (Negative years are 'BC')
    public var yearString: String? {
        return DateFormatter.wmf_yearString(for: year?.intValue ?? 0, with: language)
    }
}
