var webpackConfig = require('./webpack.config.js');
webpackConfig.entry = {};

module.exports = function(config) {
  config.set({
    basePath: '',
    frameworks: ['tap'],

    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: true,
    browsers: ['Chrome'],
    singleRun: true,
    autoWatchBatchDelay: 300,

    files: [
      './tests/tests.js'],

    preprocessors: {
      './tests/tests.js': ['webpack', 'sourcemap']
    },

    webpack: webpackConfig,

    webpackMiddleware: {
      noInfo: true
    },

    reporters: ['tap-pretty'],

    tapReporter: {
      prettifier: 'tap-spec',
      separator: true
    },
  });
}
