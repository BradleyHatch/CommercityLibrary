// Note: You must restart bin/webpack-watcher for changes to take effect
/* eslint global-require: 0 */
/* eslint import/no-dynamic-require: 0 */

const webpack = require('webpack')
const { join, resolve } = require('path')

module.exports = {
  entry: join(__dirname, './../src/load_components.js'),

  output: {
    path: join(__dirname, "./../../javascripts/c/components"),
    filename: "components.js",
    libraryTarget: 'var',
    library: 'Components'
  },

  resolve: {
    modules: [
      resolve(__dirname, './../src'),
      "node_modules"
    ],
    extensions: [
      ".js", ".json", ".jsx", ".style.js"
    ]
  },

  module: {
    rules: [
      { test: /\.scss$/, use: ['style-loader', 'css-loader', 'postcss-loader', 'sass-loader'], exclude: '/node_modules/'},
      { test: /\.css$/, use: [ "style-loader", "css-loader" ], exclude: '/node_modules/'},
      { test: /\.js$|.jsx$/, loader: "babel-loader", query:{presets:['es2015', 'stage-0', 'react'], plugins: ['transform-decorators-legacy']}, exclude: '/node_modules/'},
      // { test: /\.js$|.jsx$/, loader: "eslint-loader", exclude: '/node_modules/'}
    ],
  },

  plugins: [
    new webpack.LoaderOptionsPlugin({
      options: {
        eslint: {
            configFile: '.eslintrc',
            failOnWarning: false,
            failOnError: false,
            fix: false,
            quiet: false
          }
        }
      })
    ]
}
