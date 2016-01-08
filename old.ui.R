require(shiny)
require(dplyr)

games <- readRDS("EldritchData.rds.gz")

shinyUI(fluidPage(
  titlePanel("Predict your Eldritch Horror outcome"),
  column(4,
  selectInput("ancient.one", "Select Ancient One", levels(games$Ancient.One)),
  selectizeInput("investigators", "Select Investigators", names(games)[12:35], multiple = T),
  checkboxInput("prelude", "Prelude Card?"),
  checkboxInput("startingrumor", "Starting Rumor?"),
  checkboxInput("mysteryreshuffled", "Mystery Reshuffle?"),
  checkboxGroupInput("expansions", "Select Expansions",
                     choices = c("Forsaken.Lore", "Mountains.of.Madness", "Strange.Remnants")),
  selectInput("mythos", "Mythos modifications", levels(games$Mythos.modification), "None")),
  column(8, verbatimTextOutput("result"),
         hr(),
         "Data taken from this ",
         a("Eldritch Horror Statistics Google Doc",
           href = "https://docs.google.com/spreadsheets/d/1ZdxFQZu-5jT9zyTRuE0JCFR4KmlRSMTx1G0bZntfdWA/edit#gid=40"))
))