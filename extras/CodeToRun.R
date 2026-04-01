library(DemoCohortDiagnosticsStudy)
library(dplyr)

# Maximum number of cores to be used:
maxCores <- parallel::detectCores()

# The folder where the study intermediate and result files will be written:
homedir = "/home/jovyan/work"
outputFolder <- file.path(homedir, "output/DemoCohortDiagnosticsStudy_synthea")

# Optional: specify where the temporary files (used by the Andromeda package) will be created:
options(andromedaTempFolder = file.path(outputFolder, "andromedaTemp"))

# Details for connecting to the server:
# Database management system name; has to be one of the following:
#'sql server','oracle','postgresql','pdw','impala','netezza','bigquery','spark','sqlite','redshift','hive','sqlite extended','duckdb','snowflake','synapse'
DBMS = "postgresql"
#user name
source(file.path(homedir, "credentials.R"))

#USER = db_user
#password
#PASSWORD= db_pass
#server
SERVER = "localhost/postgres"
#port
DB_PORT = 5432
# path to local JDBC driver
pathToDriver=Sys.getenv("DATABASECONNECTOR_JAR_FOLDER")

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = DBMS,
                                                                user = db_user,
                                                                password = db_pass,
                                                                server = SERVER,
                                                                port = 5432,
                                                                pathToDriver = DB_PORT)
# The name of the database schema where the CDM data can be found:

cdmDatabaseSchema <- "cdm_synthea30k"

# The name of the database schema and table where the study-specific cohorts will be instantiated:
cohortDatabaseSchema <- "cdm_synthea30k_results"
cohortTable <- "cohort_demoAK"

# Some meta-information that will be used by the export function:
databaseId <- "synthea30k"
databaseName <- "synthea30k default database"
databaseDescription <-
  "synthea30k default database"

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
# CohortDiagnostics::createMergedResultsFile(
#  dataFolder = outputFolder,
#  sqliteDbPath = file.path(outputFolder,
#                           "MergedCohortDiagnosticsData.sqlite")
#)
#CohortDiagnostics::launchDiagnosticsExplorer(dataFolder = outputFolder)
