// This file is a part of Projman, a group project orchestrator and management system,
// made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

document.addEventListener('DOMContentLoaded', function() {
    var accordionSections = document.querySelectorAll('.accordion-section');
    accordionSections.forEach(section => {

        var accordionElements = section.querySelectorAll('.accordion-element');
        var backToTopButton = section.querySelector('#backToTopButton');
        accordionElements.forEach(element => {
            var currentAccordionElement = element
            var toggleElement = element.querySelector('[data-accordion-toggle]');
            toggleElement.classList.add('collapsed');

            // Attach onclick event to the toggle element
            if (toggleElement) {
                // Collapse class is toggled RIGHT BEFORE this event fires
                toggleElement.addEventListener('click', () => {
                    if(!toggleElement.classList.contains('collapsed')){


                        //On Opening Section, close all other sections,
                        accordionElements.forEach(element => {
                            if(element == currentAccordionElement) return;
                            var toggleElement = element.querySelector('[data-accordion-toggle]');
                            if(!toggleElement) return;

                            var expanded = toggleElement.getAttribute('aria-expanded');
                            if(expanded == "true"){
                                toggleElement.click();
                            }
                        })
                        //show backToTopButton, make its onClick function a scroll that targets this toggle element
                        if(!backToTopButton) return;
                        backToTopButton.classList.add('show');
                        console.log("back to top button will focus on: " + toggleElement)
                        backToTopButton.addEventListener('click', () => {
                            toggleElement.scrollIntoView({behavior: 'smooth', block:'start'});
                        })
                    }
                    //closing the open section hides the onclick button
                    else{
                        if(!backToTopButton) return;
                        backToTopButton.classList.remove('show');
                    }
                });

            }
        });
    });
});