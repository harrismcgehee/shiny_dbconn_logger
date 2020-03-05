#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(DBI)  # for dbconn::log_query; DBI::dbConnect; DBI::dbDisconnect
library(glue) # for `logger`
library(logger) # for logger::log_*
library(digest) # for digest::sha1_digest
library(RSQLite) # for RSQLite::SQLite()
library(remotes) # for remotes::install_github
if (!require("dbconn")) remotes::install_github("harrismcgehee/dbconn", dependencies = FALSE)


#  ----------------------------------------------------------------------

set.seed(703)

default_log_format <- "{level} [{format(time, \"%Y-%d-%m %H:%M:%S\")}] {msg}"

log_layout(layout_glue_generator(format = paste(default_log_format)))
log_info("app starting")

log_info("Connecting to DB")
con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
log_info("Connected to DB")

onStop(function() {
    log_layout(layout_glue_generator(format = paste(default_log_format)))
    log_info("Doing application cleanup\n")
    log_info('Closing connection to {Sys.getenv("db")}')
    dbDisconnect(con)
})


# Define UI for application that draws a histogram
ui <- fluidPage(
    actionButton("toggle_query_params","Toggle URL Query Params"),
    
    conditionalPanel(
        condition = "output.has_guid",
        mainPanel( id = "sql",
                verbatimTextOutput("guid_render"),
                tableOutput("sql")
        )
    )
)

server <- function(input, output, session) {

    # mimics new users visiting the page --------
            observeEvent(input$toggle_query_params , {
                if (input$toggle_query_params %% 2 == 1) {
                    # https://github.com/rstudio/shiny/issues/1874#issuecomment-338564722
                    updateQueryString(paste0("?guid=",digest::sha1_digest(runif(1))), mode = "push")
                } else {
                    updateQueryString("?", mode = "push")
                }
            })
    # -------------
    

# who is looking at the page? ---------------------------------------------
    params <- reactive({shiny::parseQueryString(session$clientData$url_search)})
    guid <- reactive({params()$guid})
    
    output$has_guid <- reactive({!is.null(guid())})
    outputOptions(output, "has_guid", suspendWhenHidden = FALSE)
            
    observe({
        if(is.null(guid())){
            log_layout(layout_glue_generator(format = paste(guid(), default_log_format)))
            log_warn("No guid")
        } else {
            log_layout(layout_glue_generator(format = paste(guid(),default_log_format)))
            log_info("Server function / page loaded")
        }
    })
#  ---------------------------------------------
    
    output$guid_render <- renderText({guid()})
    
    output$sql <- renderTable({
        req(guid())
        log_layout(layout_glue_generator(format = paste(guid(),default_log_format)))
        
        query <- paste("SELECT 1 as one")
        ### > I would want this to log the GUID
        dbconn::log_query(con, query)
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
