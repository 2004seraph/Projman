// This file is a part of Projman, a group project orchestrator and management system,
// made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

import Rails from "@rails/ujs";
import $ from 'jquery';
import 'jquery'
import 'bootstrap';
import 'bootstrap-datepicker';

import '../scripts/datepicker';
import '../scripts/list_group_control';
import '../scripts/modal_control';
import '../scripts/accordion_control';
import '../scripts/search_collection_control';
import '../scripts/selectable_row_control';

import '../scripts/custom-functions';

import '../scripts/project/project_creation_control';
import '../scripts/student/module_students_control';
import '../scripts/teams/teams_control';

window.$ = $

Rails.start();

function showLoadingModal() {
  $('#loadingModal').modal('show');
}

function hideLoadingModal() {
  $('#loadingModal').modal('hide');
}

window.showLoadingModal = showLoadingModal;
window.hideLoadingModal = hideLoadingModal;