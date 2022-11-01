/* eslint global-require: 0 */
// Note: You must run bin/webpack for changes to take effect

const webpack = require('webpack')
const merge = require('webpack-merge')
const sharedConfig = require('./webpack.shared.config.js')

module.exports = merge(sharedConfig, {
  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify('production')
      }
    }),
    new webpack.optimize.AggressiveMergingPlugin(),
    new webpack.optimize.UglifyJsPlugin({
      minimize: true
    })
  ]
})
