require(dplyr)
require(caret)
require(randomForest)
require(googlesheets)
require(reshape2)
require(ggplot2)

# FIRST BUILD A MODEL FOR DEFEAT/VICTORY
# Read in the spreadsheet
games <- "https://docs.google.com/spreadsheets/d/1ZdxFQZu-5jT9zyTRuE0JCFR4KmlRSMTx1G0bZntfdWA/edit#gid=40" %>%
  gs_url %>% gs_read("Submissions") %>%
  # Factor variables that should be factors
  mutate(Ancient.One = factor(Ancient.One), Mythos.modification = factor(Mythos.modification),
         Result = factor(Result),
         # Build in logicals for combinatorial variables
         Outcome = factor(gsub(" .*", "", Result)),
         Forsaken.Lore = grepl("Forsaken Lore", Expansions),
         Mountains.of.Madness = grepl("Mountains of Madness", Expansions),
         Strange.Remnants = grepl("Strange.Remnants", Expansions),
         Prelude = grepl("Prelude", Options), Starting.rumor = grepl("Starting Rumor", Options)) %>% 
  # Remove uninformative columns
  select(-Timestamp, -Nickname, -Options, -Expansions, -Special.Events, -Score, -Doom.track,
         -Defeated, -Devoured, -Game.Length, -Epic.Monsters, -Rumors.Passed, -Rumors.Failed)

# Make logicals for all investigators
all_investigators <- games$Investigators %>% strsplit(", ") %>%
  unlist %>% factor %>% levels %>% gsub("\"", "", .)
for (investigator in all_investigators) {
  games[[investigator]] <- grepl(investigator, games$Investigators)
}
investigator_classes <-
  list("Acquirer" = c("Charlie", "Finn", "George", "Marie", "Trish"),
       "Buffer" = c("Leo", "Lola", "Silas"),
       "Fighter" = c("Skids", "Lily", "Mark", "Tommy", "Wilson", "Zoey"),
       "Modifier" = c("Tony", "Akachi", "Norman", "Patrice", "Ursula"),
       "Spellcaster" = c("Agnes", "Daisy", "Diana", "Jacqueline", "Jim"))
for (investigator_class in names(investigator_classes)) {
  games[[paste0("Num.", investigator_class)]] <-
    lapply(strsplit(games$Investigators, ", "), function(x) {
      length(intersect(x, investigator_classes[[investigator_class]]))
      })
}

games.old <- games %>% select(-Investigators)
games <- games.old %>% select(-Result)
saveRDS(games.old, "EldritchData.rds.gz", compress = T)

# Tweak mtry
accuracies <- data.frame(mtry = c(), accuracy = c())
for (mt in rep(3:12, 5)) {
  train <- createDataPartition(games$Outcome, p = 0.8, list = F)
  gamesTr <- games[train,]
  gamesTe <- games[-train,]
  rf <- randomForest(Outcome ~ ., gamesTr, mtry = mt, ntree = 100) # Less trees to speed this step up
  pr_rf <- predict(rf, gamesTe)
  accuracies <- accuracies %>%
    rbind(data.frame(mtry = mt, accuracy = confusionMatrix(pr_rf, gamesTe$Outcome)$overall[1])) %>%
    tbl_df
}
accuracies %>% group_by(mtry) %>% summarize(avg = mean(accuracy), sd = sd(accuracy)) %>%
  arrange(-avg)
# Well that doesn't seem to matter too much..

# OK so let's make the final model
rf <- randomForest(Outcome ~ ., games, mtry = 5, type = "prob")
saveRDS(rf, "FinalEldritchModel.Outcome.rds.gz", compress = T)


# NOW MAKE A MODEL OF RESULT
games <- games.old %>% select(-Outcome)

accuracies <- data.frame(mtry = c(), accuracy = c())
for (mt in rep(3:12, 5)) {
  train <- createDataPartition(games$Result, p = 0.8, list = F)
  gamesTr <- games[train,]
  gamesTe <- games[-train,]
  rf <- randomForest(Result ~ ., gamesTr, mtry = mt)
  pr_rf <- predict(rf, gamesTe)
  accuracies <- accuracies %>%
    rbind(data.frame(mtry = mt, accuracy = confusionMatrix(pr_rf, gamesTe$Result)$overall[1])) %>%
    tbl_df
}
accuracies %>% group_by(mtry) %>% summarize(avg = mean(accuracy), sd = sd(accuracy)) %>%
  arrange(-avg)

rf <- randomForest(Result ~ ., games, mtry = 5, type = "prob")
saveRDS(rf, "FinalEldritchModel.Result.rds.gz", compress = T)

# shinyapps::deployApp("/home/khturner/EldritchML/")