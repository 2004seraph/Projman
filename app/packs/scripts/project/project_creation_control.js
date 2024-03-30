import $ from 'jquery';

$(function() {

    function runChecks() {
        // Project choices enable checkbox change event
        var projectChoicesChecked = $('#project-choices-enable').is(':checked');
        $('#project-choices .card-body').toggleClass('display-none', !projectChoicesChecked);
        $('#project-preference-form-deadline-row').toggleClass('display-none', !projectChoicesChecked);

        // Team allocation method select box change event
        var teamAllocationMethodValue = $('#team-allocation-method').val();
        $('#team-preference-form-settings').toggleClass('display-none', teamAllocationMethodValue !== "preference_based_team_allocation");
    }

    runChecks();

    $(document).on('change', '#project-choices-enable', function() {
        runChecks();

    });
    $(document).on('change', '#team-allocation-method', function() {
        runChecks();
    });
});