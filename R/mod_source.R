
source_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::tagList(
    shiny::tags$br(),
    shiny::fluidRow(
      shiny::column(6,
                    shiny::selectizeInput(ns("record"), label = NULL, choices = NULL,
                                          multiple = TRUE, width = "500px", options = list(maxItems = 1))
      ),
      shiny::column(6,
                    shiny::actionButton(ns("add"), "Add source"),
                    shiny::actionButton(ns("delete"), "Delete source")
      )
      
    ),
    
    shinyjs::hidden(
      shiny::fluidRow(id = ns("sour_tabs"),
                      shiny::column(12,
                                    shiny::tabsetPanel(
                                      shiny::tabPanel("Summary", source_summary_ui(ns("sour_summary"))),
                                      shiny::tabPanel("Data", source_data_ui(ns("sour_data"))),
                                      shiny::tabPanel("Details", source_details_ui(ns("sour_details"))),
                                      shiny::tabPanel("Notes", notes_ui(ns("sour_notes"))),
                                      shiny::tabPanel("Media", media_links_ui(ns("sour_media")))
                                    )
                      )
      )
    )
  )
}

source_server <- function(id, r) {
  moduleServer(id, function(input, output, session) {
    
    # Update list of sources
    records <- shiny::reactive({
      req(r$ged)
      
      tidyged::xrefs_sour(r$ged) %>% 
        tidyged::describe_records(r$ged, ., short_desc = TRUE)
    })
    
    # Update choices with list of sources and select one
    observeEvent(records(), {
      if(!is.null(records())) {
        
        if(is.null(r$sour_to_select)) {
          current_selection <- input$record
        } else {
          current_selection <- r$sour_to_select
        }
        
        shiny::updateSelectizeInput(session = session, inputId = "record", choices = records(), selected = current_selection)
      } else {
        shiny::updateSelectizeInput(session = session, inputId = "record", choices = character(), selected = character())
      }
      r$sour_to_select <- NULL
    })
    
    # Update sour_rows
    shiny::observeEvent(priority = 2, {
      input$record
      r$ged
    }, {
      req(input$record)
      sour_xref <- stringr::str_extract(input$record, tidyged.internals::reg_xref(FALSE))
      r$sour_rows <- which(r$ged$record == sour_xref)
    })
    
    # Show/hide tabs and toggle delete button
    shiny::observeEvent(input$record, ignoreNULL = FALSE, {
      shinyjs::toggle("sour_tabs", condition = !is.null(input$record))
      shinyjs::toggleState("delete", !is.null(input$record))
    })
    
    # Add source and set a flag to ensure it is selected
    observeEvent(input$add, {
      r$ged <- tidyged::add_sour(r$ged)
      sour_xrefs <- tidyged::xrefs_sour(r$ged)
      last_sour <- tail(sour_xrefs, 1)
      r$sour_to_select <- tidyged::describe_records(r$ged, last_sour, short_desc = TRUE)
    })
    
    # Remove source and set a flag to ensure no source is selected
    observeEvent(input$delete, {
      sour_xref <- stringr::str_extract(input$record, tidyged.internals::reg_xref(FALSE))
      r$ged <- tidyged::remove_sour(r$ged, sour_xref)
      shiny::showNotification("Source deleted")
      r$sour_to_select <- NULL
    })
    
    source_summary_server("sour_summary", r)
    source_data_server("sour_data", r)
    source_details_server("sour_details", r)
    notes_server("sour_notes", r, "sour_rows")
    media_links_server("sour_media", r, "sour_rows")
    
  })
}


