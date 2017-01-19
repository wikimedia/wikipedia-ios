//https://msdn.microsoft.com/en-us/library/bb259689.aspx
//http://wiki.openstreetmap.org/wiki/QuadTiles

typealias QuadKey = UInt64
typealias QuadKeyPart = UInt32
typealias QuadKeyPrecision = UInt16
typealias QuadKeyDegrees = Double

extension QuadKeyPrecision {
    static let max: QuadKeyPrecision = 32
    
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
}

extension QuadKeyDegrees {
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
}

extension QuadKeyPart {
    
    init(latitude: QuadKeyDegrees) {
        let nonZeroLatitude = latitude + QuadKeyDegrees.latitudeMax
        let partInDegrees = nonZeroLatitude * QuadKeyDegrees.latitudeToPartConstant
        self.init(QuadKeyPart(partInDegrees.rounded()))
    }
    
    init(longitude: QuadKeyDegrees) {
        let nonZeroLongitude = longitude + QuadKeyDegrees.longitudeMax
        let partInDegrees = nonZeroLongitude * QuadKeyDegrees.longitudeToPartConstant
        self.init(QuadKeyPart(partInDegrees.rounded()))
    }
    
    init(latitude: QuadKeyDegrees, precision: QuadKeyPrecision) {
        let fullPart = QuadKeyPart(latitude: latitude)
        let part = fullPart >> QuadKeyPart(QuadKeyPrecision.max - precision)
        self.init(part)
    }
    
    init(longitude: QuadKeyDegrees, precision: QuadKeyPrecision) {
        let fullPart = QuadKeyPart(longitude: longitude)
        let part = fullPart >> QuadKeyPart(QuadKeyPrecision.max - precision)
        self.init(part)
    }
    
    static func max(atPrecision precision: QuadKeyPrecision) -> QuadKeyPart {
        return QuadKeyPart(QuadKey(1) << QuadKey(precision) - 1)
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

extension QuadKey {
    init(latitude: QuadKeyDegrees, longitude: QuadKeyDegrees) {
        self.init(latitudePart: QuadKeyPart(latitude: latitude), longitudePart: QuadKeyPart(longitude: longitude), precision: QuadKeyPrecision.max)
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
}

struct QuadKeyCoordinate {
    let latitudePart: QuadKeyPart
    let longitudePart: QuadKeyPart
    
    init (latitudePart: QuadKeyPart, longitudePart: QuadKeyPart) {
        self.latitudePart = latitudePart
        self.longitudePart = longitudePart
    }
    
    init(quadKey: QuadKey, precision: QuadKeyPrecision) {
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
        self.init(latitudePart: latitudePart, longitudePart: longitudePart)
    }
    
    init(quadKey: QuadKey) {
        self.init(quadKey: quadKey, precision: QuadKeyPrecision.max)
    }
}

struct QuadKeyBounds {
    let min: QuadKey
    let max: QuadKey
    
    init(min: QuadKey, max: QuadKey) {
        self.min = min
        self.max = max
    }
    
    init(quadKey: QuadKey, precision: QuadKeyPrecision) {
        let min = quadKey << QuadKey(64 - 2*precision)
        let mask = precision >= 32 ? QuadKey(0) : QuadKey.max >> QuadKey(2*precision)
        let max = min | mask
        self.init(min: min, max: max)
    }
}


