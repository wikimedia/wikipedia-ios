const path = require('path');

module.exports = {
  entry: {
    PCSHTMLConverter: './PCSHTMLConverter.js',
    Polyfill: './Polyfill.js'
  },
  output: {
    path: path.resolve(__dirname, 'build'),
    filename: '[name].js',
    library: '[name]'
  },
  devtool: 'source-map',
  module: {
    rules: [
      {
        test: /\.m?js$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: [['@babel/preset-env', {"targets": { "android": "5.0", "ios": "11.0"}}]],
            compact: false
          }
        }
      }
    ]
  }
};