// This file is a part of Projman, a group project orchestrator and management system,
// made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

import $ from 'jquery';
import 'bootstrap';

$(function() {

    var projectPrefMinDate = ""
    var teamPrefMinDate = ""

    var projectPrefDateInput = $('#project-preference-form-deadline-row #project-preference-form-deadline')
    var teamPrefDateInput = $('#teammate-preference-form-deadline-row #teammate-preference-form-deadline')
    if (projectPrefDateInput.prop('min') !== undefined) {
        projectPrefMinDate = projectPrefDateInput.prop('min');
    }
    if (teamPrefDateInput.prop('min') !== undefined) {
        teamPrefMinDate = teamPrefDateInput.prop('min');
    }

    function runChecks() {

        var projectChoicesChecked = $('#project-choices-enable').is(':checked');
        var teamAllocationMethodValue = $('#team-allocation-method').val();

        var projectPrefDateInput = $('#project-preference-form-deadline-row #project-preference-form-deadline')
        var teamPrefDateInput = $('#teammate-preference-form-deadline-row #teammate-preference-form-deadline')

        if(!projectChoicesChecked){        
            // Min attribute exists, get value and then delete it
            if (projectPrefDateInput.prop('min') !== undefined) {
                projectPrefMinDate = projectPrefDateInput.prop('min');
                projectPrefDateInput.removeAttr('min');
            }
        }
        else{
            // set or add min attribute to the min value
            projectPrefDateInput.prop('min', projectPrefMinDate);
        }

        if(teamAllocationMethodValue !== "preference_form_based"){
            //Min attribute exists, get value and then delete it
            if (teamPrefDateInput.prop('min') !== undefined) {
                teamPrefMinDate = teamPrefDateInput.prop('min');
                teamPrefDateInput.removeAttr('min');
            }
        }
        else{
            // set or add min attribute to the min value
            teamPrefDateInput.prop('min', teamPrefMinDate);
        }

        $('#project-choices .card-body').toggleClass('display-none', !projectChoicesChecked);
        $('#project-preference-form-deadline-row').toggleClass('display-none', !projectChoicesChecked);
        

        $('#team-preference-form-settings').toggleClass('display-none', (teamAllocationMethodValue !== "preference_form_based"));
        $('#teammate-preference-form-deadline-row').toggleClass('display-none', (teamAllocationMethodValue !== "preference_form_based"));


    }

    runChecks();

    $(document).on('change', '#project-choices-enable', function() {
        runChecks();

    });
    $(document).on('change', '#team-allocation-method', function() {
        runChecks();
    });
    $(document).on('change', '#project-allocation-method', function() {
        runChecks();
    });

    // Emailing Modal Control
    $(document).on('click', '#timings .milestone-row button.milestone-email-btn', function(event) {

        var removeBtn = $("#milestone-email-modal #milestone-email-remove-btn")
        removeBtn.addClass("display-none");

        var milestoneName = $(this).closest('.milestone-row').find('.hidden-row-value').val();
        if (!milestoneName) {
            return;
        }

        var modal = $('#milestone-email-modal');
        var submitButton = modal.find('button[type="submit"]');
        var modalValue = modal.find('input[type="hidden"].hidden-modal-value');
        var emailInput = modal.find('#milestone-email-input');
        var advanceInput = modal.find('#milestone-email-modal-advance-day-picker');

        modalValue.val(milestoneName);
        submitButton.prop('disabled', true);
        //Clear Inputs
        emailInput.val('');

        //Send AJAX to request email data
        $.ajax({
            url: '/projects/get_milestone_data',
            type: 'GET',
            dataType: 'json',
            data: { milestone_name: milestoneName },
            success: function(response) {

                // check if milestone has email field
                if("Email" in response){
                    emailInput.val(response.Email.Content);
                    advanceInput.val(response.Email.Advance === "" ? "7" : response.Email.Advance);

                    // show remove button
                    removeBtn.removeClass("display-none");
                    submitButton.prop('disabled', false);
                }
            },
            error: function(xhr, status, error) {
                console.error(xhr.responseText);
            }
        });
    });
    $(document).on('click', '#milestone-email-modal #milestone-email-remove-btn', function(){
        var milestoneName = $("#milestone-email-modal input[type='hidden'][name='milestone_name']").val()
        //Send AJAX to delete the email field from the JSON
        $.ajax({
            url: '/projects/remove_milestone_email',
            type: 'GET',
            dataType: 'json',
            data: { milestone_name: milestoneName },
            success: function(response) {
            },
            error: function(xhr, status, error) {
                console.error(xhr.responseText);
            }
        });
    })


    //  comment modal control
    $(document).on('click', '#timings .milestone-row button.milestone-comment-btn', function(event) {
        var milestoneName = $(this).closest('.milestone-row').find('.hidden-row-value').val();
        console.log(milestoneName)
        if (!milestoneName) {
            return;
        }

        var modal = $('#milestone-comment-modal');
        var submitButton = modal.find('button[type="submit"]');
        var modalValue = modal.find('input[type="hidden"].hidden-modal-value');
        var commentInput = modal.find('#milestone-comment-input');

        modalValue.val(milestoneName);
        submitButton.prop('disabled', true);
        //Clear Inputs
        commentInput.val('');

        //Send AJAX to request email data
        $.ajax({
            url: '/projects/get_milestone_data',
            type: 'GET',
            dataType: 'json',
            data: { milestone_name: milestoneName },
            success: function(response) {
                commentInput.val(response.Comment);
                submitButton.prop('disabled', false);
            },
            error: function(xhr, status, error) {
                console.error(xhr.responseText);
            }
        });
    });
});