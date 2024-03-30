import $ from 'jquery';

$(function() {
    $(document).on('change', '#project-choices-enable', function() {
        var isChecked = $(this).is(':checked');
        console.log("Checkbox checked: ", isChecked);
        var projectChoicesUrl = $(this).data('url');

        $('#project-choices .card-body').toggleClass('display-none', !isChecked);
        $('#project-preference-form-deadline-row').toggleClass('display-none', !isChecked);

        // Send an AJAX request
        $.ajax({
            url: projectChoicesUrl,
            method: 'POST',
            data: { isChecked: isChecked },
            success: function(response) {
            },
            error: function(xhr, status, error) {
                // Handle the error response
                console.error('AJAX request failed:', error);
            }
        });
    });
});