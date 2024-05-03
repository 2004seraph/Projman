// This file is a part of Projman, a group project orchestrator and management system,
// made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

const { generateWebpackConfig, merge } = require('shakapacker')
const webpack = require('webpack');

const options = {
  resolve: {
    extensions: ['.css', '.scss']
  },
  plugins: [
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      'window.jQuery': 'jquery',
      Popper: ['popper.js', 'default']
    })
  ]
};

module.exports = merge({}, generateWebpackConfig(), options)