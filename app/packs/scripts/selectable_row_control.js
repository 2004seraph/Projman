import $ from 'jquery'

$(function(){
    const rowClick = new CustomEvent('row-selection-change');

    $.fn.getSelectedRows = function() { 
        if (!$(this).hasClass('selectable-row-container')) {
            console.error('getSelectedRows can only be called on a selectable-row-container');
            return [];
        }
        var selectedRows = [];
        $(this).find('tr.selectable-row').each(function() {
            var checkbox = $(this).find('.form-check-input');
            if (checkbox.prop('checked')) {
                selectedRows.push(this);
            }
        });
        return selectedRows;
    };

    $('.selectable-row-container').each(function() {
        var selectableRowContainer = $(this);

        selectableRowContainer.on('click', 'tr.selectable-row', function(event) {
            if ($(event.target).prop('tagName') !== 'INPUT') {
                var checkbox = $(this).find('.form-check-input');
                checkbox.prop('checked', !checkbox.prop('checked'));
            }
            selectableRowContainer[0].dispatchEvent(rowClick);
        });
    });
});