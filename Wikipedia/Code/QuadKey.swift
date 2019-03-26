import Foundation

//https://msdn.microsoft.com/en-us/library/bb259689.aspx
//http://wiki.openstreetmap.org/wiki/QuadTiles

public typealias QuadKey = UInt64 // The address of a square on the QuadKey grid. For example, at precision 1 - 00 = top left, 01 = top right, 10 = bottom left, 11 = bottom right. For each higher precision level, two bits are appended corresponding to where the point falls in the next smallest division. 0000 = top left square of the top left square, 0011 = bottom right square of the top left square, 1011 bottom right square of the bottom left square. For higher precisions, the pattern continues.
public typealias QuadKeyPart = UInt32 // A longitude or latitude coordinate on the QuadKey grid. At each precision level, the latitude or longitude range is divided into pow(2, precision) parts. Where the point falls indicates the value. At precision 1: 0 = lower half, 1 = upper half, at precision 2: 01 upper half of the lower half, 11 upper half of the upper half. Interleaving the bits of the latitude and longitude parts is what makes a quad key.
public typealias QuadKeyPrecision = UInt16 // The precision of a QuadKey ( 1 = divide the world into 4 quarters once, 2 = divide the world in 4, then each subsection in 4, 3 = divide the world in 4, then each subsection in 4, then each subsection and 4 again, generally the number of squares at a given precision = pow(4, precision)
public typealias QuadKeyDegrees = Double // A latitude or longitude in degrees

public extension QuadKeyPrecision {
    static let maxPrecision: QuadKeyPrecision = 32
    
    var deltaLatitude: QuadKeyDegrees {
        get {
            return QuadKeyDegrees.latitudeRangeLength/QuadKeyDegrees(1 << QuadKey(self))
        }
    }
    
    var deltaLongitude: QuadKeyDegrees {
        get {
            return QuadKeyDegrees.longitudeRangeLength/QuadKeyDegrees(1 << QuadKey(self))
        }
    }
    
    init(deltaLatitude: QuadKeyDegrees) {
        var delta = deltaLatitude
        if delta.isInfinite || delta > QuadKeyDegrees.latitudeRangeLength {
            delta = QuadKeyDegrees.latitudeRangeLength
        } else if delta.isNaN || delta <= 0.0001 {
            delta = 0.0001
        }
        let precision = (log(QuadKeyDegrees.latitudeRangeLength/delta)/log(2)).rounded()
        self.init(precision)
    }
    
    init(deltaLongitude: QuadKeyDegrees) {
        var delta = deltaLongitude
        if delta.isInfinite || delta > QuadKeyDegrees.longitudeRangeLength {
            delta = QuadKeyDegrees.longitudeRangeLength
        } else if delta.isNaN || delta <= 0.0001 {
            delta = 0.0001
        }
        let precision = (log(QuadKeyDegrees.longitudeRangeLength/delta)/log(2)).rounded()
        self.init(precision)
    }
}

public extension QuadKeyDegrees {
    static let latitudeMax: QuadKeyDegrees = 90
    static let longitudeMax: QuadKeyDegrees = 180
    
    static let latitudeRangeLength: QuadKeyDegrees = 180
    static let longitudeRangeLength: QuadKeyDegrees = 360
    
    static let partToLatitudeConstant: QuadKeyDegrees =  latitudeRangeLength / QuadKeyDegrees(QuadKeyPart.max)
    static let partToLongitudeConstant: QuadKeyDegrees = longitudeRangeLength / QuadKeyDegrees(QuadKeyPart.max)
    
    static let latitudeToPartConstant: QuadKeyDegrees =  QuadKeyDegrees(QuadKeyPart.max) / latitudeRangeLength
    static let longitudeToPartConstant: QuadKeyDegrees =  QuadKeyDegrees(QuadKeyPart.max) / longitudeRangeLength
    
    init(latitudePart: QuadKeyPart, precision: QuadKeyPrecision) {
        self.init(QuadKeyDegrees.latitudeRangeLength*QuadKeyDegrees(latitudePart)/QuadKeyDegrees(QuadKeyPart.max(atPrecision: precision)) - QuadKeyDegrees.latitudeMax)
    }
    
    init(longitudePart: QuadKeyPart, precision: QuadKeyPrecision) {
        self.init(QuadKeyDegrees.longitudeRangeLength*QuadKeyDegrees(longitudePart)/QuadKeyDegrees(QuadKeyPart.max(atPrecision: precision)) - QuadKeyDegrees.longitudeMax)
    }
    
    init(latitudePart: QuadKeyPart) {
        self.init(QuadKeyDegrees(latitudePart)*QuadKeyDegrees.partToLatitudeConstant - QuadKeyDegrees.latitudeMax)
    }
    
    init(longitudePart: QuadKeyPart) {
        self.init(QuadKeyDegrees(longitudePart)*QuadKeyDegrees.partToLongitudeConstant - QuadKeyDegrees.longitudeMax)
    }
    
    var latitudePart: QuadKeyPart {
        get {
            return QuadKeyPart(latitude: self)
        }
    }
    
    var longitudePart: QuadKeyPart {
        get {
            return QuadKeyPart(longitude: self)
        }
    }
    
    func latitudePart(atPrecision precision: QuadKeyPrecision) -> QuadKeyPart {
        return QuadKeyPart(latitude: self, precision: precision)
    }
    
    func longitudePart(atPrecision precision: QuadKeyPrecision) -> QuadKeyPart {
        return QuadKeyPart(longitude: self, precision: precision)
    }
    
    static func max(_ a: QuadKeyDegrees, _ b: QuadKeyDegrees) -> QuadKeyDegrees {
        return a > b ? a : b
    }
    
    static func min(_ a: QuadKeyDegrees, _ b: QuadKeyDegrees) -> QuadKeyDegrees {
        return a < b ? a : b
    }
}

public extension QuadKeyPart {
    
    init(latitude: QuadKeyDegrees) {
        guard latitude.isFinite else {
            self.init(QuadKeyPart(0))
            return
        }
        let nonNegativeLatitude = QuadKeyDegrees.min(QuadKeyDegrees.latitudeRangeLength, QuadKeyDegrees.max(0, latitude + QuadKeyDegrees.latitudeMax))
        let partInDegrees = nonNegativeLatitude * QuadKeyDegrees.latitudeToPartConstant
        self.init(QuadKeyPart(partInDegrees.rounded()))
    }
    
    init(longitude: QuadKeyDegrees) {
        guard longitude.isFinite else {
            self.init(QuadKeyPart(0))
            return
        }
        let nonNegativeLongitude = QuadKeyDegrees.min(QuadKeyDegrees.longitudeRangeLength, QuadKeyDegrees.max(0, longitude + QuadKeyDegrees.longitudeMax))
        let partInDegrees = nonNegativeLongitude * QuadKeyDegrees.longitudeToPartConstant
        self.init(QuadKeyPart(partInDegrees.rounded()))
    }
    
    init(latitude: QuadKeyDegrees, precision: QuadKeyPrecision) {
        let fullPart = QuadKeyPart(latitude: latitude)
        let part = fullPart >> QuadKeyPart(QuadKeyPrecision.maxPrecision - precision)
        self.init(part)
    }
    
    init(longitude: QuadKeyDegrees, precision: QuadKeyPrecision) {
        let fullPart = QuadKeyPart(longitude: longitude)
        let part = fullPart >> QuadKeyPart(QuadKeyPrecision.maxPrecision - precision)
        self.init(part)
    }
    
    static func max(atPrecision precision: QuadKeyPrecision) -> QuadKeyPart {
        let one: QuadKey = QuadKey(1)
        let precisionAsQuadKey: QuadKey = QuadKey(precision)
        let oneShiftedByPrecision: QuadKey = one << precisionAsQuadKey
        return QuadKeyPart(oneShiftedByPrecision - one)
    }
    
    var latitude: QuadKeyDegrees {
        get {
            return QuadKeyDegrees(latitudePart: self)
        }
    }
    
    var longitude: QuadKeyDegrees {
        get {
            return QuadKeyDegrees(longitudePart: self)
        }
    }
    
    func latitude(atPrecision precision: QuadKeyPrecision) -> QuadKeyDegrees {
        return QuadKeyDegrees(latitudePart: self, precision: precision)
    }
    
    func longitude(atPrecision precision: QuadKeyPrecision) -> QuadKeyDegrees {
        return QuadKeyDegrees(longitudePart: self, precision: precision)
    }
    
    var bitmaskString: String {
        var string = ""
        var value = self
        for _ in 1...32 {
            string.insert(Character("\(value & 1)"), at: string.startIndex)
            value >>= 1
        }
        return string
    }
}

public extension QuadKey {
    static let unsignedConversionConstant: UInt64 = UInt64(bitPattern: Int64.min)
    static let signedConversionConstant: Int64 = Int64.min
    
    init(latitude: QuadKeyDegrees, longitude: QuadKeyDegrees) {
        self.init(latitudePart: QuadKeyPart(latitude: latitude), longitudePart: QuadKeyPart(longitude: longitude), precision: QuadKeyPrecision.maxPrecision)
    }

    init(latitude: QuadKeyDegrees, longitude: QuadKeyDegrees, precision: QuadKeyPrecision) {
        self.init(latitudePart: QuadKeyPart(latitude: latitude, precision: precision), longitudePart: QuadKeyPart(longitude: longitude, precision: precision), precision: precision)
    }
    
    init(latitudePart: QuadKeyPart, longitudePart: QuadKeyPart, precision: QuadKeyPrecision) {
        var quadKey: QuadKey = 0
        let max: QuadKey = QuadKey(precision) - 1
        let quadKeyLongitudePart = QuadKey(longitudePart)
        let quadKeyLatitudePart = QuadKey(latitudePart)
        var i = max
        var done = false
        while !done {
            let shiftedLongitudePart = quadKeyLongitudePart >> i
            quadKey = (quadKey << 1) | (shiftedLongitudePart & 1)
            let shiftedLatitudePart = quadKeyLatitudePart >> i
            quadKey = (quadKey << 1) | (shiftedLatitudePart & 1)
            if i == 0 {
                done = true
            } else {
                i -= 1
            }
        }
        self.init(quadKey)
    }
    
    init(int64: Int64) {
        if int64 >= 0 {
            self.init(UInt64(int64) + QuadKey.unsignedConversionConstant)
        } else {
            let remainder = int64 - QuadKey.signedConversionConstant
            self.init(remainder)
        }
    }
    
    func adjusted(downBy precision: QuadKeyPrecision) -> QuadKey {
        let shift = QuadKey(2*precision)
        return self >> shift
    }
    
    var bitmaskString: String {
        var string = ""
        var value = self
        for _ in 1...64 {
            string.insert(Character("\(value & 1)"), at: string.startIndex)
            value >>= 1
        }
        return string
    }
    
    func coordinate(precision: QuadKeyPrecision) -> QuadKeyCoordinate {
        return QuadKeyCoordinate(quadKey: self, precision: precision)
    }
    
    var coordinate: QuadKeyCoordinate {
        return coordinate(precision: QuadKeyPrecision.maxPrecision)
    }
    
    var longitude: QuadKeyDegrees {
        return coordinate.longitude
    }
    
    var latitude: QuadKeyDegrees {
        return coordinate.latitude
    }
}

public extension Int64 {
    init(quadKey: QuadKey) {
        if quadKey < QuadKey.unsignedConversionConstant {
            self.init(Int64(quadKey) + QuadKey.signedConversionConstant)
        } else {
            let remainder = quadKey - QuadKey.unsignedConversionConstant
            self.init(remainder)
        }
    }
}

public struct QuadKeyCoordinate {
    public let latitudePart: QuadKeyPart
    public let longitudePart: QuadKeyPart
    public let precision: QuadKeyPrecision
    
    public init (latitudePart: QuadKeyPart, longitudePart: QuadKeyPart, precision: QuadKeyPrecision) {
        self.latitudePart = latitudePart
        self.longitudePart = longitudePart
        self.precision = precision
    }
    
    public init(quadKey: QuadKey, precision: QuadKeyPrecision) {
        var latitudePart: QuadKeyPart = 0
        var longitudePart: QuadKeyPart = 0
        var i: QuadKey = 2*QuadKey(precision) - 1
        
        var done = false
        while !done {
            longitudePart = (longitudePart << 1) | QuadKeyPart(((quadKey >> i) & 1))
            i -= 1
            latitudePart = (latitudePart << 1) | QuadKeyPart(((quadKey >> i) & 1))
            if i == 0 {
                done = true
            } else {
                i -= 1
            }

        }
        self.init(latitudePart: latitudePart, longitudePart: longitudePart, precision: precision)
    }
    
    public init(quadKey: QuadKey) {
        self.init(quadKey: quadKey, precision: QuadKeyPrecision.maxPrecision)
    }
    
    public var latitude: QuadKeyDegrees {
        get {
            return precision < QuadKeyPrecision.maxPrecision ? latitudePart.latitude(atPrecision: precision) : latitudePart.latitude
        }
    }
    
    public var longitude: QuadKeyDegrees {
        get {
            return precision < QuadKeyPrecision.maxPrecision ? longitudePart.longitude(atPrecision: precision) : longitudePart.longitude
        }
    }
    
    public var centerLatitude: QuadKeyDegrees {
        get {
            let halfDeltaLatitude = 0.5 * precision.deltaLatitude
            return latitude - halfDeltaLatitude
        }
    }
    
    public var centerLongitude: QuadKeyDegrees {
        get {
            let halfDeltaLongitude = 0.5 * precision.deltaLongitude
            return longitude + halfDeltaLongitude
        }
    }
}

public struct QuadKeyBounds {
    public let min: QuadKey
    public let max: QuadKey
    
    public init(min: QuadKey, max: QuadKey) {
        self.min = min
        self.max = max
    }
    
    public init(quadKey: QuadKey, precision: QuadKeyPrecision) {
        let min = quadKey << QuadKey(64 - 2*precision)
        let mask = precision >= 32 ? QuadKey(0) : QuadKey.max >> QuadKey(2*precision)
        let max = min | mask
        self.init(min: min, max: max)
    }
}


