

// Remove the list group item that the pressed button is associated with
function deleteGroupItem(button) {
    var listItem = button.closest('.list-group-item');
    listItem.remove();
}