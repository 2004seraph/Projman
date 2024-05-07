// This file is a part of Projman, a group project orchestrator and management system,
// made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

// This file includes javascript that is necessary for the functionality of the project teams page

import $ from 'jquery';
import 'bootstrap';

$(function() {
  $('#project-teams-container').on('click', '.edit-facilitator-btn', function(event) {
    var teamContainer = $(this).closest('.project-teams-team-container');
    var team_id = teamContainer.find('input[type="hidden"][name="team_id"]').val();
    var facilitatorsModal = $('#facilitators_modal')
    var noFacilitatorsModal = $('#no_facilitators_modal')

    function initialiseFacilitatorsModal(partials, currentFacilitator){
      var modalBody = facilitatorsModal.find('.modal-body')
      modalBody.empty();
      facilitatorsModal.find('input[type="hidden"][name="team_id"]').val(team_id)
      partials.forEach(function(partial) {
        // Append each partial to the modal body
        $(partial).appendTo(modalBody);
      });

      var appendedPartials = facilitatorsModal.find('.modal-body .facilitator-option')
      appendedPartials.each(function(index, partial){
        var input = $(partial).find('input').first();
        var emailLabel = $(partial).find('label').first();
        var emailText = emailLabel.text().trim();

        // Check if the text content matches current facilitator email
        if (emailText === currentFacilitator) {
          input.prop('checked', true).trigger('change');
        }
        else{
          input.prop('checked', false).trigger('change');
        }
      })
    }

    $.ajax({
      url: 'teams/' + team_id + '/facilitator_emails',
      type: 'POST',
      dataType: 'json',
      data: {
        team_id: team_id
      },
      headers: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      },
      success: function(response) {
        var facilitator_emails = response.facilitator_emails
        var team_facilitator = response.team_facilitator

        if(facilitator_emails.length > 0){
          facilitatorsModal.modal('show')
          initialiseFacilitatorsModal(response.partials, team_facilitator)
        }
        else{
          noFacilitatorsModal.modal('show')
        }
      },
      error: function(xhr, status, error) {
        console.log(error)
      }
    });
  });

  $('#facilitators_modal').on('click', '.facilitator-option label', function(event){
    event.preventDefault();
    event.stopPropagation();
    var clickedLabel = event.target
    var input = $(clickedLabel).siblings('input');
    if(!input.prop('checked')){
      // uncheck all others
      var allOptions = $('#facilitators_modal .facilitator-option input[type="checkbox"')
      allOptions.each(function(index, option){
        var option = $(option);
        option.prop('checked', false).trigger('change');
      })

      // check the clicked input
      input.prop('checked', true).trigger('change');
    }
  });

  $('#facilitators_modal').on('click', '#set-facilitator-btn', function(event){

    var facilitatorsModal = $('#facilitators_modal')
    var team_id = facilitatorsModal.find('input[type="hidden"][name="team_id"]').val()
    var facilitatorOptions = facilitatorsModal.find('.modal-body .facilitator-option')
    var facilitatorToAdd = ""
    facilitatorOptions.each(function(index, option){
      var input = $(option).find('input').first();

      if(input.prop('checked')){
        var emailLabel = $(option).find('label').first();
        facilitatorToAdd = emailLabel.text().trim();
        return false; // break jquery loop
      }
    })

    $.ajax({
      url: 'teams/' + team_id + '/set_facilitator',
      type: 'POST',
      data: {
        facilitator_email: facilitatorToAdd
      },
      headers: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      },
      success: function(){
        
      },
      error: function(xhr, status, error) {
        console.log(error)
      }
    });
  });
})