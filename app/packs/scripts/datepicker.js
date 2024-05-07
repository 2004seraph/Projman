// This file is a part of Projman, a group project orchestrator and management system,
// made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

import $ from 'jquery';

$(function(){
    $.fn.datepicker.defaults.format = 'dd/mm/yyyy';
    $('.datepicker').datepicker({
        format: 'dd/mm/yyyy'
    });

    $('.datepicker-calender-icon-addon').on('click', function() {
      $(this).next('.datepicker-input').datepicker('show');
    });
});