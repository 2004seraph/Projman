

document.addEventListener('DOMContentLoaded', function() {
    // Get all elements of type list-group-item-partial
    var listGroupItems = document.querySelectorAll('.list-group-item-partial');

    // Loop through each list group item
    listGroupItems.forEach(function(item) {
        // Get the attached button on the list group item
        var button = item.querySelector('button.btn-delete');

        // Set onclick function to execute deleteGroupItem functionality
        button.onclick = function() {
            var listItem = button.closest('.list-group-item');
            listItem.remove();
        };
    });
});