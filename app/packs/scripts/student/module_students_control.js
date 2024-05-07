// This file is a part of Projman, a group project orchestrator and management system,
// made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

import $ from 'jquery';
import 'bootstrap';

$(function() {

    // couldnt get bootstrap js to work (.modal('show)), so instead i manipulate the elements
    //on the remove students modal
    function updateRemoveStudentsModal(studentEmails){
        var modal = document.querySelector('#removeStudentsModal');
        var modalBody = modal.querySelector('.modal-body');
        var modalFooter = document.querySelector('.modal-footer');
        var cancelButton = modalFooter.querySelector('.btn:nth-child(1)');
        var removeButton = modalFooter.querySelector('.btn:nth-child(2)');
        if (studentEmails.length === 0) {
            modalBody.textContent = "Please select students to remove.";

            // Hide "REMOVE" button, make "CANCEL" primary
            removeButton.classList.add("display-none")
            cancelButton.classList.remove("btn-secondary")
            cancelButton.classList.add("btn-primary")
            cancelButton.textContent = "OK"

        } else {
            modalBody.innerHTML = "Remove the following students?<br>" + studentEmails.join("<br>");

            //Show both buttons normally
            cancelButton.classList.remove("btn-primary")
            cancelButton.classList.add("btn-secondary")
            cancelButton.textContent = "Cancel"

            removeButton.classList.remove("display-none")
            removeButton.textContent = "Yes, remove them"
        }
    }

    var studentsOnModuleContainers = $('.students-on-module-container')
    studentsOnModuleContainers.each(function(){
        var listBoxReference = $(this).attr("id")
        var selectableRowContainer = $(this).find('.selectable-row-container').first()
        var removeBtn = $(this).find('.remove-students-btn').first()
        var emails = []

        //if we get bootstrap js to work:
        //If empty, show empty modal
        //Otherwise, show standard modal, and populate it


        //Give remove student modal submit button an ajax action on click that sends the list of student emails to nuke from the module
        //  -> also give the ajax json data field the reference of the module being removed from
        //on success of said nuking (controller side), call a format.js file that will remove all rows with the removed emails, FOR THAT MODULE (use reference given)

        // collect emails from rows
        removeBtn.on('click', function(){
            console.log(listBoxReference)
            var selectedRows = selectableRowContainer.getSelectedRows()
            //extract emails
            selectedRows.forEach(function(row) {
                var email = $(row).children('td').eq(2).text();
                emails.push(email)
            });
            updateRemoveStudentsModal(emails)


            // now define an AJAX with jquery for the submit button of the remove students modal submit button
            // ensure that all emails passed in ARE INDEED VALID EMAILS of students on the module, to make sure that
            // you havent tried to remove an email that was inserted via inspect element.
            // remove any students where the email is indeed valid, call format.js file which will then remove associated rows

            // also you will need to authorize the action of whatever ajax route you are calling in to to be accessible by the staff (check ability.rb)
        })
    })
})