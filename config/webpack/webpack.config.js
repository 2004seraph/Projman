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