// This file is a part of Projman, a group project orchestrator and management system,
// made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

import $ from 'jquery';

$(function() {
    // Event delegation for button deletion functionality
    $(document).on('click', '.list-group-item-partial button.btn-delete', function(event) {
        event.preventDefault();
        var listItem = $(this).closest('.list-group-item-partial');
        var form_action = listItem.attr('form_action');
        var itemText = listItem.find('input[item_text]').val();

        // Make the AJAX request
        $.ajax({
            url: form_action, // Get the form action URL
            method: 'POST',
            data: {item_text: itemText},
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function(response) {
                // Handle success response here
                listItem.remove(); // Remove the list item
            },
            error: function(xhr, status, error) {
                // Handle error response here
                console.error("AJAX request failed:", error);
            }
        });
    });
});