document.addEventListener('DOMContentLoaded', function () {

    const rowClick = new CustomEvent('row-selection-change');


    document.querySelectorAll('.selectable-row-container').forEach((selectableRowContainer) => {

        selectableRowContainer.getSelectedRows = function () {
            var selectedRows = []
            var selectableRows = selectableRowContainer.querySelectorAll('tr.selectable-row');
            selectableRows.forEach(row => {
                // Check if the row contains a .form-check-input:checked element
                var isChecked = row.querySelector('.form-check-input:checked');
                
                // If checked element exists, add the row to selectedRows
                if (isChecked) {
                    selectedRows.push(row);
                }
            });
            return selectedRows
        }

        rows = selectableRowContainer.querySelectorAll('tr.selectable-row')
        rows.forEach((row) => {
            row.addEventListener('click', (event) => {
                // Check if the clicked element is not an input
                if (event.target.tagName !== 'INPUT') {
                    var checkbox = row.querySelector('.form-check-input');
                    // Toggle checkbox state
                    checkbox.checked = !checkbox.checked;
                }
                selectableRowContainer.dispatchEvent(rowClick);
            });
        });
    })
});