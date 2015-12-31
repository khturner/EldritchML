require(shiny)
require(dplyr)

games <- readRDS("EldritchData.rds.gz")

shinyUI(fluidPage(
  titlePanel("Predict your Eldritch Horror outcome"),
  column(4,
  selectInput("ancient.one", "Select Ancient One", levels(games$Ancient.One)),
  selectizeInput("investigators", "Select Investigators", names(games)[11:34], multiple = T),
  checkboxInput("prelude", "Prelude Card?"),
  checkboxInput("startingrumor", "Starting Rumor?"),
  checkboxInput("mysteryreshuffled", "Mystery Reshuffle?"),
  checkboxGroupInput("expansions", "Select Expansions",
                     choices = c("Forsaken.Lore", "Mountains.of.Madness", "Strange.Remnants")),
  selectInput("mythos", "Mythos modifications", levels(games$Mythos.modification), "None")),
  column(8, verbatimTextOutput("result"))
))