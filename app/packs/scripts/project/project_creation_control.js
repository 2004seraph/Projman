import $ from 'jquery';

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

        $('#team-preference-form-settings').toggleClass('display-none', (teamAllocationMethodValue !== "preference_based_team_allocation"));
        $('#teammate-preference-form-deadline-row').toggleClass('display-none', (teamAllocationMethodValue !== "preference_based_team_allocation"));
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
});