homedir = "/Users/andreikiselev/Documents/Rdevelopment"
outputFolder <- file.path(homedir, "StudyResults/DemoCohortDiagnosticsStudy_lungcancer_synthea10k")

CohortDiagnostics::createMergedResultsFile(
  dataFolder = outputFolder,
  sqliteDbPath = file.path(outputFolder,
                           "MergedCohortDiagnosticsData.sqlite")
)
CohortDiagnostics::launchDiagnosticsExplorer(sqliteDbPath = file.path(outputFolder,
                                                                      "MergedCohortDiagnosticsData.sqlite"))
