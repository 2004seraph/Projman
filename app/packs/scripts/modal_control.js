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

    // Ensure inputs are valid 
    modals.forEach(function(modal) {
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