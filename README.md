
# To reproduce:

+ `shiny::runApp("app.R")`
+ Click the `Toggle URL Query Params` button 3 times. 

# Console output:

Attempting to log the `guid` query parameter from `dbconn::log_query` via the `layout_glue_my` when it is available.

In the console log we get this:

```
runApp()
INFO [2020-05-03 11:43:34] app starting
INFO [2020-05-03 11:43:34] Connecting to DB
INFO [2020-05-03 11:43:34] Connected to DB

Listening on http://127.0.0.1:6376
 WARN [2020-05-03 11:43:36] No guid
40f98383f34366568c79919cb19019abb04e7cd4 INFO [2020-05-03 11:43:38] Server function / page loaded
40f98383f34366568c79919cb19019abb04e7cd4 INFO [2020-05-03 11:43:38] about to run query SELECT 1 as one
40f98383f34366568c79919cb19019abb04e7cd4 INFO [2020-05-03 11:43:38] Ran query SELECT 1 as one with 1 rows returned
 WARN [2020-05-03 11:43:39] No guid
5f5ab64ce0e412b5aa7ecdc813d4e7b158384600 INFO [2020-05-03 11:43:39] Server function / page loaded
5f5ab64ce0e412b5aa7ecdc813d4e7b158384600 INFO [2020-05-03 11:43:39] about to run query SELECT 1 as one
5f5ab64ce0e412b5aa7ecdc813d4e7b158384600 INFO [2020-05-03 11:43:39] Ran query SELECT 1 as one with 1 rows returned
 
INFO [2020-05-03 11:43:48] Doing application cleanup
INFO [2020-05-03 11:43:48] Closing connection to 
```

Notice `INFO about to run query SELECT 1 as one` **does** have the `guid`.

# Shortcoming:

This works well for 1 user or for apps with infrequent overlapping usage.

However, you could get into a situation with multiple users where you have two sessions:

|  time|  guid ABC|  no guid| log|
|--:|--:|--:|--:|
|  1|  Arrive|  | |
|  2|  set guid|  | |
|  3| log arrival|  | `ABC INFO [2020-05-03 11:43:38] Server function / page loaded` |
|  4|  |  Arrive| |
|  5|  |  clear guid| |
|  6|  |  log arrival| ` WARN [2020-05-03 11:43:36] No guid` |
|  7| log SQL |  |  `INFO [2020-05-03 11:43:39] about to run query SELECT 1 as one`|
