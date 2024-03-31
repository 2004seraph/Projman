
import $ from 'jquery';

$(function() {
    // Event delegation for button deletion functionality
    $(document).on('click', '.list-group-item-partial button.btn-delete', function(event) {
        event.preventDefault();
        var listItem = $(this).closest('.list-group-item-partial');
        var form_action = listItem.attr('form_action');
        var itemText = listItem.find('input[item_text]').val();
        console.log(itemText)
    
        // Make the AJAX request
        $.ajax({
            url: form_action, // Get the form action URL
            method: 'POST',
            data: {item_text: itemText},
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