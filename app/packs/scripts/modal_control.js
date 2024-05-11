// This file is a part of Projman, a group project orchestrator and management system,
// made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

document.addEventListener('DOMContentLoaded', function () {

    // Clearing Modal Input fields upon opening them
    var modals = document.querySelectorAll('.modal');
    modals.forEach(function(modal) {
        modal.addEventListener('show.bs.modal', function () {

            // CLEAR INPUT FIELDS
            var inputFields = modal.querySelectorAll('input[type="text"], textarea, input[type="search"]');
            var confirmButton = modal.querySelector('.btn.btn-primary[type="submit"]');

            if(!confirmButton){
                confirmButton = modal.querySelector('.confirm-action-btn');
            }
            inputFields.forEach(function(inputField) {
                inputField.value = ''; // Clear the input field
                confirmButton.disabled = true;
            });

            // IF THIS IS A SEARCH-MULTIPLE-MODAL, CLEAR LIST
            if (modal.classList.contains('search-multiple-modal')) {
                // Find the element with the class ".list-group" and remove all its children
                var listGroup = modal.querySelector('.list-group');
                listGroup.innerHTML = ''; // Remove all children
            }
            //IF MODAL HAS A ON-OPEN-ACTION DEFINED, POST IT WITH AJAX
            // Check if the modal has the data-on-open-action attribute
            var onOpenActionUrl = modal.getAttribute('data-on-open-action');
            if (onOpenActionUrl && onOpenActionUrl !== '') {
                // Send AJAX request to the path specified in the attribute
                $.ajax({
                    url: onOpenActionUrl,
                    method: 'POST',
                    success: function(response) {
                    },
                    error: function(xhr, status, error) {
                        // Handle error response
                        console.error("AJAX request failed:", error);
                    }
                });
            }
        });

    });

    // Ensure modals with an input field cant have the field left empty
    modals.forEach(function(modal) {

        if (modal.hasAttribute('data-disallow-confirm-group-empty')) {
            var inputField = modal.querySelector('input');
            var confirmButton = modal.querySelector('.btn.btn-primary[type="submit"]');
            var listGroup = modal.querySelector('.list-group');

            if(!confirmButton){
                confirmButton = modal.querySelector('.confirm-action-btn');
            }

            // Function to enable confirm button based on list group children
            function toggleConfirmButton() {
                confirmButton.disabled = true
                if (listGroup && listGroup.children.length > 0) {
                    if (confirmButton) {
                        confirmButton.disabled = false; // Enable the confirm button
                    }
                }
            }
            if (inputField && confirmButton) {
                confirmButton.disabled = true;

                toggleConfirmButton();
                var observer = new MutationObserver(function(mutations) {
                    mutations.forEach(function(mutation) {
                        if (mutation.type === 'childList') {
                            toggleConfirmButton();
                        }
                    });
                });
                observer.observe(listGroup, { childList: true });
                inputField.addEventListener('input', toggleConfirmButton);
            }
        }

        if (modal.hasAttribute('data-disallow-confirm-empty-input')) {
            var inputFields = modal.querySelectorAll('input[type="text"], textarea, input[type="search"]');
            var confirmButton = modal.querySelector('.btn.btn-primary[type="submit"]');

            if(!confirmButton){
                confirmButton = modal.querySelector('.confirm-action-btn');
            }

            if (inputFields.length > 0 && confirmButton) {
                confirmButton.disabled = true;

                inputFields.forEach(function(inputField) {
                    inputField.addEventListener('input', function() {
                        var allFieldsFilled = true;
                        inputFields.forEach(function(field) {
                            if (field.value.trim() === '') {
                                allFieldsFilled = false;
                                return;
                            }
                        });

                        confirmButton.disabled = !allFieldsFilled;
                    });
                });
            }
        }
    });
});