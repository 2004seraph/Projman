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
        
        if (modal.hasAttribute('data-disallow-confirm-group-empty')) {
            var inputField = modal.querySelector('input');
            var confirmButton = modal.querySelector('.btn-primary[type="submit"]');
            var listGroup = modal.querySelector('.list-group');
    
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
            var inputField = modal.querySelector('input[type="text"]');
            var confirmButton = modal.querySelector('.btn-primary[type="submit"]');

            if (inputField && confirmButton) {
                confirmButton.disabled = true;

                inputField.addEventListener('input', function() {
                    if (inputField.checkValidity()) {
                        confirmButton.disabled = false;
                    }
                });
            }
        }
    });
});