import Rails from "@rails/ujs";
import $ from 'jquery';
import 'bootstrap';
import 'bootstrap-datepicker';

Rails.start();

$(function(){
    $('.datepicker').datepicker({
        format: 'dd/mm/yyyy'
    });
});

$(function() {
    $('.datepicker-calender-icon-addon').on('click', function() {
      $(this).next('.datepicker-input').datepicker('show');
    });
});