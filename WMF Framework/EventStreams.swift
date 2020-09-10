import Foundation

extension EPC {
    /**
     * Streams are the event stream identifiers that can be utilized with the EventPlatformClientLibrary. They should
     *  correspond to the `$id` of a schema in
     * [this repository](https://gerrit.wikimedia.org/g/schemas/event/secondary/).
     */
    public enum Stream: String, Codable {
        case editHistoryCompare = "ios.edit_history_compare"
    }
    
    /**
     * Schema specifies which schema (and specifically which version of that schema)
     * a given event conforms to. Analytics schemas can be found in the jsonschema directory of
     * [secondary repo](https://gerrit.wikimedia.org/g/schemas/event/secondary/).
     * As an example, if instrumenting client-side error logging, a possible
     * `$schema` would be `/mediawiki/client/error/1.0.0`. For the most part, the
     * `$schema` will start with `/analytics`, since there's where
     * analytics-related schemas are collected.
     */
    public enum Schema: String, Codable {
        case editHistoryCompare = "/analytics/mobile_apps/ios_edit_history_compare/1.0.0"
    }
}

