import $ from 'jquery';

$(function(){
    $('.datepicker').datepicker({
        format: 'dd/mm/yyyy'
    });

    $('.datepicker-calender-icon-addon').on('click', function() {
      $(this).next('.datepicker-input').datepicker('show');
    });
});