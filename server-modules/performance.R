calculatePerformance <- function(df, input){

  if(input$dateCol == "") {
    
    df <- df[,c(input$xCol,input$yCol)]
    df <- df[complete.cases(df), ]
    df[,"quints"] <- NA
    
    df$quints <- quint(as.numeric(df[,input$xCol]))
    
    # Create performance DF
    allPerformance <- data.frame(Quintile = c("Q1 (Highest)", "Q2", "Q3", "Q4", "Q5 (Lowest)"))
    allPerformance[,"All"] <- NA
    quintMeans <- aggregate(df[, input$yCol], by = list(df$quints), function(x) mean(x, na.rm = TRUE))
    for(quint in quintMeans[,"Group.1"]){
      allPerformance[quint,"All"] <- quintMeans[grep(quint,quintMeans[,"Group.1"]),"x"]
    }
    performanceDifferential <- ((allPerformance[1, "All"] * 2 + allPerformance[2, "All"]) / 3) - ((allPerformance[5, "All"] * 2 + allPerformance[4, "All"]) / 3)
    allPerformance[6, "All"] <- performanceDifferential
    
    return(allPerformance)
  }
  
  df <- df[,c(input$xCol,input$yCol,input$dateCol)]
  df <- df[complete.cases(df), ]
  df[,"quints"] <- NA
    
  aggs <- by(df, INDICES = df[, input$dateCol], function(x) {
    tryCatch({
      #if(length((x[,input$xCol])) >= 5)
      x[,"quints"] <- quint(as.numeric(x[,input$xCol]))
    }, error = function(e) {
      x[,"quints"] <- rep(NA, nrow(x))
    })
    x
  })

  dfquints <- do.call("rbind", aggs)
  # Create performance DF
  allPerformance <- data.frame(Quintile = c("Q1 (Highest)", "Q2", "Q3", "Q4", "Q5 (Lowest)"))
  allPerformance[,"All"] <- NA
  quintMeans <- aggregate(dfquints[, input$yCol], by = list(dfquints$quints), function(x) mean(x, na.rm = TRUE))
  for(quint in quintMeans[,"Group.1"]){
    allPerformance[quint,"All"] <- quintMeans[grep(quint,quintMeans[,"Group.1"]),"x"]
  }
  performanceDifferential <- ((allPerformance[1, "All"] * 2 + allPerformance[2, "All"]) / 3) - ((allPerformance[5, "All"] * 2 + allPerformance[4, "All"]) / 3)
  allPerformance[6, "All"] <- performanceDifferential
  
  # Calculate performance by quintile for each date, populate performance df
  if(input$dateCol != "") {
    for(date in unique(as.character(df[, input$dateCol]))) {
      datedf <- df[df[,input$dateCol] == date, ]

      allPerformance[, as.character(date)] <- NA
      tryCatch({
        datedf[, "quints"] <- quint(datedf[,input$xCol])
        aggs <- aggregate(datedf[, input$yCol], by = list(datedf$quints), function(x) mean(x, na.rm = TRUE))
        performanceDifferential <- ((aggs[1, "x"] * 2 + aggs[2, "x"]) / 3) - ((aggs[5, "x"] * 2 + aggs[4, "x"]) / 3)
        for(row in 1:nrow(aggs)){
          allPerformance[aggs[row, 1], as.character(date)] <- aggs[row, "x"]
        }
        allPerformance[6, as.character(date)] <- performanceDifferential

      }, error = function(e) {
        allPerformance[, as.character(date)] <- rep(NA,nrow(allPerformance))
      })
    }
  }
          
  allPerformance[6, "Quintile"] <- "Performance Differential"
  return(allPerformance)
}