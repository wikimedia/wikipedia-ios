public final class WMFExploreDataController {

    private let userDefaultsStore: WMFKeyValueStore?

    public init(userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore) {
        self.userDefaultsStore = userDefaultsStore
    }

    // MARK: - Community Modules

    public func communityFeaturedArticleIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityFeaturedArticleIsOn.rawValue)) ?? true
    }

    public func setCommunityFeaturedArticleIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityFeaturedArticleIsOn.rawValue, value: newValue)
    }

    public func communityTopReadIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityTopReadIsOn.rawValue)) ?? true
    }

    public func setCommunityTopReadIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityTopReadIsOn.rawValue, value: newValue)
    }

    public func communityInTheNewsIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityInTheNewsIsOn.rawValue)) ?? true
    }

    public func setCommunityInTheNewsIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityInTheNewsIsOn.rawValue, value: newValue)
    }

    public func communityOnThisDayIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityOnThisDayIsOn.rawValue)) ?? true
    }

    public func setCommunityOnThisDayIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityOnThisDayIsOn.rawValue, value: newValue)
    }

    public func communityPictureOfTheDayIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedCommunityPictureOfTheDayIsOn.rawValue)) ?? true
    }

    public func setCommunityPictureOfTheDayIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedCommunityPictureOfTheDayIsOn.rawValue, value: newValue)
    }

    // MARK: - For You Modules

    public func forYouBasedOnInterestsIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedForYouBasedOnInterestsIsOn.rawValue)) ?? true
    }

    public func setForYouBasedOnInterestsIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedForYouBasedOnInterestsIsOn.rawValue, value: newValue)
    }

    public func forYouBecauseYouReadIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedForYouBecauseYouReadIsOn.rawValue)) ?? true
    }

    public func setForYouBecauseYouReadIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedForYouBecauseYouReadIsOn.rawValue, value: newValue)
    }

    public func forYouContinueReadingIsOn() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.homeFeedForYouContinueReadingIsOn.rawValue)) ?? true
    }

    public func setForYouContinueReadingIsOn(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.homeFeedForYouContinueReadingIsOn.rawValue, value: newValue)
    }
}
