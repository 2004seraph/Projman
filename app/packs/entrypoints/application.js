import Rails from "@rails/ujs";
import $ from 'jquery';
import 'bootstrap';
import 'bootstrap-datepicker';

Rails.start();

$(function(){
    $('.datepicker').datepicker();
});