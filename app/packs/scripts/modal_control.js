document.addEventListener('DOMContentLoaded', function () {

    // Clearing Modal Input fields upon opening them
    var modals = document.querySelectorAll('.modal');
    modals.forEach(function(modal) {
        modal.addEventListener('show.bs.modal', function () {
        var inputFields = modal.querySelectorAll('input[type="text"]');
        inputFields.forEach(function(inputField) {
            inputField.value = ''; // Clear the input field
        });
        });
    });

    // Ensure modals with an input field cant have the field left empty
    modals.forEach(function(modal) {

        // some modals will have you build up a list of items to submit, so the input field
        // could be left empty
        if (modal.hasAttribute('data-allow-confirm-empty-input')) {
            return; // Skip this modal
        }

        var inputField = modal.querySelector('input[type="text"]');
        var confirmButton = modal.querySelector('.btn-primary[type="submit"]');

        if (inputField && confirmButton) {
        confirmButton.disabled = true;

        inputField.addEventListener('input', function() {
            if (inputField.checkValidity()) {
            confirmButton.disabled = false;
            } else {
            confirmButton.disabled = true;
            }
        });
        }
    });
});