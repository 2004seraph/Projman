
import $ from 'jquery';

$(function() {
    // Event delegation for button deletion functionality
    $(document).on('click', '.list-group-item-partial button.btn-delete', function() {
        var listItem = $(this).closest('.list-group-item-partial');
        var form_action = listItem.find('form').attr('action');
        
        // Make the AJAX request
        $.ajax({
            url: form_action, // Get the form action URL
            method: 'POST',
            data: listItem.find('form').serialize(), // Serialize form data
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

// Add Partial of type 'group-item-simple'
function addNewSimpleGroupItem(inputField, groupId, clearInput=false) {
    itemText = inputField.value 
    var newPartialHTML = "#{escape_javascript(render(partial: 'components/group-item-simple', locals: { item_text: 'ITEM_TEXT' }))}".replace('ITEM_TEXT', itemText);
    appendPartial(inputField, newPartialHTML, groupId, clearInput)
}
// Add Partial of type 'group-item-date'
function addNewDateGroupItem(inputField, groupId, clearInput=false) {
    itemText = inputField.value 
    var newPartialHTML = "#{escape_javascript(render(partial: 'components/group-item-date', locals: { item_text: 'ITEM_TEXT' }))}".replace('ITEM_TEXT', itemText);
    appendPartial(inputField, newPartialHTML, groupId, clearInput)
}
function appendPartial(inputField, newPartialHTML, groupId, clearInput){
    var listGroup = document.getElementById(groupId);
    if (listGroup) {
        listGroup.insertAdjacentHTML('beforeend', newPartialHTML);
    }
    if(clearInput){
        inputField.value = '';
    }
}