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

sql <- "SELECT cohort_definition_id AS target_id,
       ROW_NUMBER() OVER (PARTITION BY cohort_definition_id ORDER BY cohort_start_date) AS id,
       DATEDIFF(day, cohort_start_date, event_date) AS time_to_event,
       event
FROM (
     SELECT t.cohort_definition_id, t.cohort_start_date,
            coalesce(min(o.cohort_start_date), max(t.cohort_end_date)) AS event_date,
            CASE WHEN min(o.cohort_start_date) IS NULL THEN 0 ELSE 1 END AS event
     FROM @cohort_database_schema.@cohort_table t
         LEFT JOIN (
            SELECT subject_id, MIN (cohort_start_date) AS cohort_start_date
            FROM @cohort_database_schema.@cohort_table
            WHERE cohort_definition_id IN (@outcome_ids)
            GROUP BY subject_id
          ) o
         ON t.subject_id = o.subject_id
            AND o.cohort_start_date >= t.cohort_start_date
            AND o.cohort_start_date <= t.cohort_end_date
     WHERE t.cohort_definition_id IN (@target_ids)
     GROUP BY t.cohort_definition_id, t.subject_id, t.cohort_start_date
     ) tab;"

connection <- DatabaseConnector::connect(connectionDetails)

outcomeIds <- c(3)
targetIds <- c(1,2)

renderSql <- SqlRender::render(sql = sql,
                               cohort_database_schema = cohortDatabaseSchema,
                               cohort_table = cohortTable,
                               outcome_ids = outcomeIds,
                               target_ids = paste(targetIds, collapse = ', '))
translateSql <- SqlRender::translate(sql = renderSql,
                                     targetDialect = connection@dbms)


km_grouped <- DatabaseConnector::querySql(connection, translateSql, snakeCaseToCamelCase = T)
km_grouped_1 <- km_grouped[km_grouped$targetId == 1,]

surv_right <- survival::Surv(time = km_grouped_1$timeToEvent,
                             time2 = 1500,
                             event = km_grouped_1$event,
                             type = 'interval')
survfit2(Surv(timeToEvent, event) ~ 1, data = km_grouped_1) |>
  ggsurvfit() +
  labs(
    x = "Days",
    y = "Overall event probability"
  ) +
  add_confidence_interval() +
  add_risktable()
