// This file is a part of Projman, a group project orchestrator and management system,
// made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

import $ from 'jquery';
import 'bootstrap';

$(function() {

    var studentsOnModuleContainers = $('.students-on-module-container')
    var emails = []
    studentsOnModuleContainers.each(function(){
        var listBoxReference = $(this).attr("id")
        var selectableRowContainer = $(this).find('.selectable-row-container').first()
        var removeBtn = $(this).find('.remove-students-btn').first()

        // collect emails from rows
        removeBtn.on('click', function(event){
            emails = []
            event.preventDefault()
            event.stopPropagation()

            var selectedRows = selectableRowContainer.getSelectedRows()
            //extract emails
            selectedRows.forEach(function(row) {
                var email = $(row).children('td').eq(2).text().trim();
                emails.push(email)
            });
            if (emails.length == 0){
                $('#noStudentsSelectedModal').modal('show')
            }
            else{
                var removeStudentsModal = $('#removeStudentsModal').modal('show')
                var modalBody = removeStudentsModal.find('.modal-body').first();
                var studentListArea = modalBody.find('.student-list-area').first()
                studentListArea.html(emails.join("<br>"));
            }
        })
    })

    $('#removeStudentsModal #confirmRemoveStudents').on('click', function(){
        // send all emails to controller to get students removed
        $.ajax({
            url: '/students/remove_students_from_module',
            type: 'POST',
            dataType: 'json',
            data: {
                emails: emails
            },
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function(response) {
                var removed_emails = response.removed_student_emails
                var module_code = response.module_code
                var module_code = "#" + module_code
                var studentsSelectableRowsContainer = $(".students-on-module-container" + module_code + " .card-body table")
                var selectableRows = studentsSelectableRowsContainer.find('.selectable-row')
                selectableRows.each(function(index, row) {
                    var email = $(row).children('td').eq(2).text().trim();
                    if(removed_emails.includes(email)){
                        row.remove();
                    }
                });
                
            },
            error: function(xhr, status, error) {
                console.error(xhr.responseText);
            }
        });
    })
})