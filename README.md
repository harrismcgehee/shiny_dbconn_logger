
# To reproduce:

+ `shiny::runApp("app.R")`

# Console output:

Attempting to log the `guid` query parameter from `dbconn::log_query` via the `layout_glue_my` when it is available.

However, in the console log we get this:

```
runApp()
INFO app starting
INFO Connecting to DB
INFO Connected to DB

Listening on http://127.0.0.1:3368
 WARN No guid
40f98383f34366568c79919cb19019abb04e7cd4 INFO Server function / page loaded
INFO about to run query SELECT 1 as one
INFO Ran query SELECT 1 as one with 1 rows returned
 WARN No guid
5f5ab64ce0e412b5aa7ecdc813d4e7b158384600 INFO Server function / page loaded
INFO about to run query SELECT 1 as one
INFO Ran query SELECT 1 as one with 1 rows returned

INFO Doing application cleanup
INFO Closing connection to 
```

Notice `INFO about to run query SELECT 1 as one` does not have the `guid`