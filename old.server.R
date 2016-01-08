require(shiny)
require(dplyr)
require(randomForest)

rf.out <- readRDS("FinalEldritchModel.Outcome.rds.gz")
rf.res <- readRDS("FinalEldritchModel.Result.rds.gz")
games <- readRDS("EldritchData.rds.gz")

shinyServer(function(input, output) {
  
  output$result <- renderPrint({
    if (length(input$investigators) >= 1 && length(input$investigators) <= 8) {
      d <- data.frame(Ancient.One = factor(input$ancient.one, levels(games$Ancient.One)),
                       Mythos.modification = factor(input$mythos, levels(games$Mythos.modification)),
                       Team.Size = length(input$investigators),
                       # Do I need outcome here?
                       Forsaken.Lore = "Forsaken.Lore" %in% input$expansions,
                       Mountains.of.Madness = "Mountains.of.Madness" %in% input$expansions,
                       Strange.Remnants = "Strange.Remnants" %in% input$expansions,
                       Prelude = input$prelude,
                       Starting.rumor = input$startingrumor,
                       Mystery.reshuffled = input$mysteryreshuffled)
      for (investigator in names(games)[12:35]) {
        d[[investigator]] <- investigator %in% input$investigators
      }
      pr.out <- predict(rf.out, d, type = "prob")
      pr.res <- predict(rf.res, d, type = "prob")
      out <- data.frame(Result = c(colnames(pr.out), "-----", colnames(pr.res)),
                        Probability = c(pr.out, 0, pr.res))
      out
    }
    else {
      "Select between 1 and 8 investigators"
    }
  })
})