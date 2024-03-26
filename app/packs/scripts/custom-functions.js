
// const jQuery = require('jquery')
import $ from 'jquery';

$(() => {
  $.fn.hasScrollBar = function() {
    return this.get(0).scrollHeight > this.height();
  }
})