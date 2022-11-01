/*global require*/
/*eslint no-undef: "off"*/

var webpack = require('webpack');
var path = require('path');

module.exports = {
  entry: './tests/tests.js',
  node: {
    fs: "empty"
  },
  resolve: {
    modules: [
      path.resolve(__dirname, "./../"),
      "node_modules"
    ],
    extensions: [
      ".js", ".json", ".jsx", ".style.js", "scss"
    ]
  },
  module: {
    rules: [
      { test: /\.scss$/, use: [ "style-loader", "css-loader", "autoprefixer-loader", "sass-loader" ], exclude: '/node_modules/'},
      { test: /\.css$/, use: [ "style-loader", "css-loader" ], exclude: '/node_modules/'},
      { test: /\.js$|.jsx$/, loader: "babel-loader", query:{presets:['react', 'es2015', 'stage-0']}, exclude: '/node_modules/'},
      { test: /\.js$|.jsx$/, loader: "eslint-loader", exclude: '/node_modules/'}
    ]
  },
  plugins: [
    new webpack.LoaderOptionsPlugin({
      options: {
        eslint:
        {
          configFile: './.eslintrc',
          failOnWarning: false,
          failOnError: false,
          fix: false,
          quiet: false
        },
      },
    }),
  ],
  devtool: 'inline-source-map'
};
