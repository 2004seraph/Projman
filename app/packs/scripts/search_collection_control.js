// This file is a part of Projman, a group project orchestrator and management system,
// made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

import $ from 'jquery';
import 'bootstrap';

$(function() {

    var searchCollections = $('.search-collection');
    searchCollections.each(function(){
        var searchCollection = $(this)
        var dropdownElement = $(this).nextAll('.dropdown-menu:first')
        var hiddenInputsContainer = $(this).nextAll('.hidden-inputs-container:first')
        searchCollection.on('click', function() {
            dropdownElement.removeClass('show');
        });

        searchCollection.on('input', function() {
            var query = $(this).val();
            var toggleElement = $(this);
            var searchUrl = $(this).attr("data-search-autocomplete-method")
            if (searchUrl === undefined || searchUrl === "") {
                return;
            }
            var requestData = {};
            // Find and iterate over hidden input elements
            hiddenInputsContainer.find('input[type="hidden"]').each(function() {
                var fieldName = $(this).attr('name');
                var value = $(this).val();
                requestData[fieldName] = value;
            });
            requestData['query'] = query

            $.ajax({
                url: searchUrl,
                type: 'GET',
                dataType: 'json',
                data: requestData,
                success: function(data) {
                    dropdownElement.empty();

                    if(data.length == 0 || query == ""){
                        dropdownElement.removeClass('show');
                    }
                    else{
                        toggleElement.trigger('click')
                    }

                    // Append new results to dropdown
                    data.forEach(function(result) {
                        dropdownElement.append('<li><a class="dropdown-item" value="' + $('<div/>').text(result).html() + '">' + $('<div/>').text(result).html() + '</a></li>');
                    });
                }
            });
        });

        dropdownElement.on('click', 'li', function() {
            // Set the value of the search bar to the value of the clicked list item
            var value = $(this).find('a').attr('value');
            if (value !== undefined) {
                searchCollection.val(value);
                dropdownElement.removeClass('show');
            }
        });
    })
});