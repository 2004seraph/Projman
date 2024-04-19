import $ from 'jquery';
import 'bootstrap';

$(function() {

    function runChecks() {

        var projectChoicesChecked = $('#project-choices-enable').is(':checked');
        var projectAllocationMethodValue = $('#project-allocation-method').val();
        var teamAllocationMethodValue = $('#team-allocation-method').val();

        $('#project-choices .card-body').toggleClass('display-none', !projectChoicesChecked);
        $('#project-preference-form-deadline-row').toggleClass('display-none', !projectChoicesChecked);

        if (projectAllocationMethodValue == "random_project_allocation" || !projectChoicesChecked){
            $('#project-preference-form-deadline-row').addClass('display-none');
        }
        else{
            $('#project-preference-form-deadline-row').removeClass('display-none');
        }

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
                emailInput.val(response.Email.Content);
                advanceInput.val(response.Email.Advance === "" ? "7" : response.Email.Advance);
                submitButton.prop('disabled', false);
            },
            error: function(xhr, status, error) {
                console.error(xhr.responseText);
            }
        });
    });
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