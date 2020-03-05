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


# functions ---------------------------------------------------------------

#' where
#' http://adv-r.had.co.nz/Environments.html#env-recursion
#' @param name x
#' @param env environment
#'
#' @return environmnet
#' @export
#'
where <- function(name, env = parent.frame()) {
    if (identical(env, emptyenv())) {
        # Base case
        # stop("Can't find ", name, call. = FALSE)
        emptyenv()
        
    } else if (exists(name, envir = env, inherits = FALSE)) {
        # Success case
        env
        
    } else {
        # Recursive case
        where(name, parent.env(env))
    }
}

# add guid to the log layout if it is available
layout_glue_my <- structure(function(level, msg, namespace = NA_character_,
                                     .logcall = sys.call(), .topcall = sys.call(-1), .topenv = parent.frame()) {
    
    if (!inherits(level, 'loglevel')) {
        stop('Invalid log level, see ?log_levels')
    }
    
    with(logger::get_logger_meta_variables(log_level = level, namespace = namespace,
                                           .logcall = .logcall, .topcall = .topcall, .topenv = .topenv),
         {
             
             format = '{level} {msg}'
             
             # this is where we search through parent environments for the shiny app’s variables
             guidenv <- try(where("guid", .topenv))
             
             # guid is reactive and needs to be evaluated
             if (!identical(guidenv, emptyenv())) {
                 format = paste(do.call(get("guid", envir = guidenv), args = list(), envir = guidenv), format)
             }
             
             
             glue::glue(format)
         })
}, generator = quote(layout_glue_my()))

#  ----------------------------------------------------------------------

set.seed(703)

log_layout(layout_glue_my)
log_info("app starting")


log_info("Connecting to DB")
con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
log_info("Connected to DB")

onStop(function() {
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
            log_warn("No guid")
        } else 
            log_info("Server function / page loaded")
        log_layout()
    })
#  ---------------------------------------------
    
    output$guid_render <- renderText({guid()})
    
    output$sql <- renderTable({
        req(guid())
        query <- paste("SELECT 1 as one")
        
        ### > I would want this to log the GUID
        dbconn::log_query(con, query)
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
