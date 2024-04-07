import $ from 'jquery';

$(function() {
    $('.search-collection').on('click', function() {
        var dropdownElement = $(this).siblings('.dropdown-menu');
        dropdownElement.removeClass('show');
    });

    $('.search-collection').on('input', function() {
        var query = $(this).val();
        var dropdownElement = $(this).siblings('.dropdown-menu');
        var searchUrl = $(this).attr("data-search-autocomplete-method")
        if (searchUrl === undefined || searchUrl === "") {
            return;
        }
    
        $.ajax({
            url: searchUrl,
            type: 'GET',
            dataType: 'json',
            data: { query: query },
            success: function(data) {
                dropdownElement.empty();

                if(data.length == 0 || query == ""){
                    dropdownElement.removeClass('show');
                }
                else{
                    dropdownElement.addClass('show');
                }

                // Append new results to dropdown
                data.forEach(function(result) {
                    dropdownElement.append('<li><a class="dropdown-item" value="' + $('<div/>').text(result).html() + '">' + $('<div/>').text(result).html() + '</a></li>');
                });
            }
        });
    });

    $('.search-collection').siblings('.dropdown-menu').on('click', 'li', function() {
        // Set the value of the search bar to the value of the clicked list item
        var value = $(this).find('a').attr('value');
        $('.search-collection').val(value);
    });
});