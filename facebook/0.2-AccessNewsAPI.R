library(httr)
library(jsonlite)
library(lubridate)
library(dplyr)
source("creds.R")

# access News API (https://newsapi.org/) to get headline articles

sources <- c("associated-press","bbc-news","bloomberg","business-insider",
             "buzzfeed","cnbc","cnn","google-news","independent","reuters",
             "the-economist", "the-huffington-post","the-new-york-times",
             "the-wall-street-journal", "the-washington-post","time","usa-today")

requestLinks <- paste0("https://newsapi.org/v1/articles?source=", 
                      sources,"&apiKey=", news.API.key) 
# for sorting: "&sortBy=latest"
allData <- vector("list", length(sources))
for(x in 1:length(sources)){
    news.source <- GET(requestLinks[x])
    news.source <- content(news.source)
    news.source <- fromJSON(toJSON(news.source))
    allData[[x]] <- news.source
}

# 'time magazine' has diff data structure
allData[[16]]$articles.publishedAt <- NULL
allData[[16]]$articles.author <- NULL

for(x in 1:length(allData)){
  allData[[x]] <- data.frame(sapply(allData[[x]], as.character),
                             stringsAsFactors = FALSE)
}


# 3/7 need to adjust the structure of the data at this point
# look into melting


# merge all
allData %>%
  Reduce( function(df1, df2) full_join(df1, df2), .) ->
allData

# not 100% vetted
allData$articles.publishedAt <- ymd_hms(allData$articles.publishedAt)

allData$TrumpFlag <- as.numeric(grepl("trump", tolower(allData$articles.title)))

allData$Retrieved <- now()
fileName <- paste0("TrumpNews", gsub(" EST", "", now()), ".csv")
fileName <- gsub(":", ".", fileName)

write.csv(allData, fileName, row.names = FALSE)
# 2017-03-05T20:52:49Z <- 3:52pm est

# add component to combine all the csvs that are in the directory
# to do trend analysis
