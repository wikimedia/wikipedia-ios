extension WMFFeedOnThisDayEvent {
    // Returns year 'era' string - i.e. '1000 AD' or '200 BC'. (Negative years are 'BC')
    public var yearWithEraString: String? {
        return DateFormatter.yearWithEraString(for: year?.intValue ?? 0, with: language)
    }
}
