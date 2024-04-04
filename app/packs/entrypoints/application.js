import Rails from "@rails/ujs";
require('jquery')
import $ from 'jquery';
import 'bootstrap';
import 'bootstrap-datepicker';

import '../scripts/datepicker';
import '../scripts/list_group_control';
import '../scripts/modal_control';
import '../scripts/accordion_control';

import '../scripts/custom-functions';

import '../scripts/project/project_creation_control';

window.$ = $

Rails.start();