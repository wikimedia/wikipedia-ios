function Transformer() {
}

var transforms = {};

Transformer.prototype.register = function( transform, fun ) {
    if ( transform in transforms ) {
        transforms[transform].push( fun );
    } else {
        transforms[transform] = [ fun ];
    }
};

Transformer.prototype.transform = function( transform ) {
    var functions = transforms[transform];
    for ( var i = 0; i < functions.length; i++ ) {
        functions[i](arguments[1], arguments[2], arguments[3], arguments[4], arguments[5], arguments[6], arguments[7], arguments[8], arguments[9], arguments[10]);
    }
};

module.exports = new Transformer();
