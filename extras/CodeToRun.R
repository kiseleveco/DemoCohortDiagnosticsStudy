library(DemoCohortDiagnosticsStudy)
library(dplyr)

# Maximum number of cores to be used:
maxCores <- parallel::detectCores()

# The folder where the study intermediate and result files will be written:
homedir = "/Users/andreikiselev/Documents/Rdevelopment"
outputFolder <- file.path(homedir, "StudyResults/DemoCohortDiagnosticsStudy_lungcancer_synthea10k")

# Optional: specify where the temporary files (used by the Andromeda package) will be created:
options(andromedaTempFolder = file.path(outputFolder, "andromedaTemp"))

# Details for connecting to the server:
# Database management system name; has to be one of the following:
#'sql server','oracle','postgresql','pdw','impala','netezza','bigquery','spark','sqlite','redshift','hive','sqlite extended','duckdb','snowflake','synapse'
DBMS = "postgresql"
#user name
source(file.path(homedir, "credentials.R"))

USER = db_user_BDM
#password
PASSWORD= db_pass_BDM
#server
SERVER = "51.15.207.59/rdb"
#port
DB_PORT = 3522
# path to local JDBC driver
pathToDriver=Sys.getenv("DATABASECONNECTOR_JAR_FOLDER")

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = DBMS,
                                                                user = USER,
                                                                password = PASSWORD,
                                                                server = SERVER,
                                                                port = DB_PORT,
                                                                pathToDriver = pathToDriver)
# The name of the database schema where the CDM data can be found:

cdmDatabaseSchema <- "lungcancer_synth10k"

# The name of the database schema and table where the study-specific cohorts will be instantiated:
cohortDatabaseSchema <- "lungcancer_synth10k_results"
cohortTable <- "cohort"

# Some meta-information that will be used by the export function:
databaseId <- "lungcancer_synth10k"
databaseName <- "lungcancer_synth10k"
databaseDescription <-
  "lungcancer_synth10k"

# For some database platforms (e.g. Oracle): define a schema that can be used to emulate temp tables:
options(sqlRenderTempEmulationSchema = NULL)

DemoCohortDiagnosticsStudy::execute(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTable = cohortTable,
  outputFolder = outputFolder,
  databaseId = databaseId,
  databaseName = databaseName,
  databaseDescription = databaseDescription
)



# if you want to view the shiny app locally, uncomment the following section
CohortDiagnostics::createMergedResultsFile(
  dataFolder = outputFolder,
  sqliteDbPath = file.path(outputFolder,
                           "MergedCohortDiagnosticsData.sqlite")
)
CohortDiagnostics::launchDiagnosticsExplorer(sqliteDbPath = file.path(outputFolder,
                                                                      "MergedCohortDiagnosticsData.sqlite"))
