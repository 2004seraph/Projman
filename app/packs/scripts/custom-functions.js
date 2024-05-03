// This file is a part of Projman, a group project orchestrator and management system,
// made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

import $ from 'jquery';

$(() => {
  $.fn.hasScrollBar = function() {
    return this.get(0).scrollHeight > this.height();
  }
})