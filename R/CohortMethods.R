# Copyright 2023 Observational Health Data Sciences and Informatics
#
# This file is part of DemoCohortDiagnosticStudy
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.



execute_CohortMethods <- function(connectionDetails,
                                  cdmDatabaseSchema,
                                  cohortDatabaseSchema = cdmDatabaseSchema,
                                  cohortTable = "cohort",
                                  outputFolder,
                                  incrementalFolder = file.path(outputFolder, "incrementalFolder"),
                                  minCellCount = 5,
                                  databaseName = databaseId,
                                  databaseDescription = databaseId,
                                  extraLog = NULL,
                                  targetId,
                                  comparatorId,
                                  outcomeId)
{


  outcomeOfInterest <- CohortMethod::createOutcome(outcomeId = outcomeId,
                                     outcomeOfInterest = TRUE)
  negativeControlIds <- read.csv("inst/negativeControlOutcomes.csv")$outcome_concept_id
  negativeControlOutcomes <- lapply(
    negativeControlIds,
    function(outcomeId) CohortMethod::createOutcome(outcomeId = outcomeId,
                                      outcomeOfInterest = FALSE,
                                      trueEffectSize = 1))

  excludedCovariateConceptIds <- exctract_concepts(outputFolder,
                                                   treatmentCohortIds = c(targetId, comparatorId))
  excludedCovariateConceptIds <- c(excludedCovariateConceptIds, c(316866, 320128, 1308216, 21601782, 21601783))

  tcos <- CohortMethod::createTargetComparatorOutcomes(
    targetId = 1,
    comparatorId = 2,
#    nestingCohortId = 3,
    outcomes = append(list(outcomeOfInterest),
                      negativeControlOutcomes),
    excludedCovariateConceptIds = excludedCovariateConceptIds
  )
  targetComparatorOutcomesList <- list(tcos)

  covarSettings <- FeatureExtraction::createDefaultCovariateSettings(
    addDescendantsToExclude = TRUE
  )
  getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(
    removeDuplicateSubjects = "remove all",
    firstExposureOnly = TRUE,
    washoutPeriod = 183,
    restrictToCommonPeriod = TRUE,
    covariateSettings = covarSettings
  )
  createStudyPopArgs <- CohortMethod::createCreateStudyPopulationArgs(
    removeSubjectsWithPriorOutcome = TRUE,
    priorOutcomeLookback = 365,
    minDaysAtRisk = 1,
    riskWindowStart = 30,
    startAnchor = "cohort start",
    riskWindowEnd = 30,
    endAnchor = "cohort end"
  )
  fitOutcomeModelArgs1 <- CohortMethod::createFitOutcomeModelArgs(
    modelType = "cox"
  )

  cmAnalysis1 <- CohortMethod::createCmAnalysis(
    analysisId = 1,
    description = "No matching, simple outcome model",
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopulationArgs = createStudyPopArgs,
    fitOutcomeModelArgs = fitOutcomeModelArgs1
  )

  createPsArgs <- CohortMethod::createCreatePsArgs() # Use default settings only
  matchOnPsArgs <- CohortMethod::createMatchOnPsArgs(
    maxRatio = 100
  )
  computeSharedCovBalArgs <- CohortMethod::createComputeCovariateBalanceArgs()
  computeCovBalArgs <- CohortMethod::createComputeCovariateBalanceArgs(
    covariateFilter = CohortMethod::getDefaultCmTable1Specifications()
  )
  fitOutcomeModelArgs2 <- CohortMethod::createFitOutcomeModelArgs(
    modelType = "cox",
    stratified = TRUE
  )
  cmAnalysis2 <- CohortMethod::createCmAnalysis(
    analysisId = 2,
    description = "Matching",
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopulationArgs = createStudyPopArgs,
    createPsArgs = createPsArgs,
    matchOnPsArgs = matchOnPsArgs,
    computeSharedCovariateBalanceArgs = computeSharedCovBalArgs,
    computeCovariateBalanceArgs = computeCovBalArgs,
    fitOutcomeModelArgs = fitOutcomeModelArgs2
  )
  stratifyByPsArgs <- CohortMethod::createStratifyByPsArgs(numberOfStrata = 10
  )

  cmAnalysis3 <- CohortMethod::createCmAnalysis(
    analysisId = 3,
    description = "Stratification",
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopulationArgs = createStudyPopArgs,
    createPsArgs = createPsArgs,
    stratifyByPsArgs = stratifyByPsArgs,
    computeSharedCovariateBalanceArgs = computeSharedCovBalArgs,
    computeCovariateBalanceArgs = computeCovBalArgs,
    fitOutcomeModelArgs = fitOutcomeModelArgs2)
  truncateIptwArgs <- CohortMethod::createTruncateIptwArgs(
      maxWeight = 10
  )
  fitOutcomeModelArgs3 <- CohortMethod::createFitOutcomeModelArgs(
    modelType = "cox",
    inversePtWeighting = TRUE,
    bootstrapCi = TRUE
  )
  cmAnalysis4 <- CohortMethod::createCmAnalysis(
    analysisId = 4,
    description = "Inverse probability weighting",
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopulationArgs = createStudyPopArgs,
    createPsArgs = createPsArgs,
    truncateIptwArgs = truncateIptwArgs,
    computeSharedCovariateBalanceArgs = computeSharedCovBalArgs,
    computeCovariateBalanceArgs = computeCovBalArgs,
    fitOutcomeModelArgs = fitOutcomeModelArgs3
  )
  fitOutcomeModelArgs4 <- CohortMethod::createFitOutcomeModelArgs(
    useCovariates = TRUE,
    modelType = "cox",
    stratified = TRUE
  )
  cmAnalysis5 <- CohortMethod::createCmAnalysis(
    analysisId = 5,
    description = "Matching plus full outcome model",
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopulationArgs = createStudyPopArgs,
    createPsArgs = createPsArgs,
    matchOnPsArgs = matchOnPsArgs,
    computeSharedCovariateBalanceArgs = computeSharedCovBalArgs,
    computeCovariateBalanceArgs = computeCovBalArgs,
    fitOutcomeModelArgs = fitOutcomeModelArgs4
  )
  interactionCovariateIds <- c(8532001, 201826210, 21600960413) # Female, T2DM, concurent use of antithrom
  fitOutcomeModelArgs5 <- CohortMethod::createFitOutcomeModelArgs(
    modelType = "cox",
    stratified = TRUE,
    interactionCovariateIds = interactionCovariateIds
  )
  cmAnalysis6 <- CohortMethod::createCmAnalysis(
    analysisId = 6,
    description = "Stratification plus interaction terms",
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopulationArgs = createStudyPopArgs,
    createPsArgs = createPsArgs,
    stratifyByPsArgs = stratifyByPsArgs,
    computeSharedCovariateBalanceArgs = computeSharedCovBalArgs,
    computeCovariateBalanceArgs = computeCovBalArgs,
    fitOutcomeModelArgs = fitOutcomeModelArgs5
  )

  cmAnalysisList <- list(cmAnalysis1,
                         cmAnalysis2,
                         cmAnalysis3,
                         cmAnalysis4,
                         cmAnalysis5,
                         cmAnalysis6)

  multiThreadingSettings <- CohortMethod::createDefaultMultiThreadingSettings(parallel::detectCores())

  result <- CohortMethod::runCmAnalyses(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = cdmDatabaseSchema,
    exposureDatabaseSchema = cohortDatabaseSchema,
    exposureTable = cohortTable,
    outcomeDatabaseSchema = cohortDatabaseSchema,
    outcomeTable = cohortTable,
    nestingCohortDatabaseSchema = cohortDatabaseSchema,
    nestingCohortTable = cohortTable,
    outputFolder = outputFolder,
    multiThreadingSettings = multiThreadingSettings,
    cmAnalysesSpecifications = CohortMethod::createCmAnalysesSpecifications(
      cmAnalysisList = cmAnalysisList,
      targetComparatorOutcomesList = targetComparatorOutcomesList
    )
  )

}

#' Extract concept codes from cohort concept set expressions
#'
#' Reads concept set expressions from a CSV file and extracts OMOP concept codes
#' for specified cohorts and concept set IDs.
#'
#' @param outputFolder Character string. Path to the folder containing
#'   \code{concept_sets.csv}.
#' @param treatmentCohortIds Vector of cohort IDs for which to extract concepts.
#' @param treatmentConceptIds Vector of concept set IDs to include.
#'
#' @return A named list where each element corresponds to a cohort ID and contains
#'   a unique character vector of extracted concept codes.
#'
#' @importFrom jsonlite fromJSON
#' @export


exctract_concepts <- function(outputFolder,
                              treatmentCohortIds){
  concepts_df <- read.csv(paste0(outputFolder, "/concept_sets.csv"))
  conceptsToExclude = list()
  concepts_df_tmp <- concepts_df[concepts_df$cohort_id %in% treatmentCohortIds, ]
  for (i in 1:nrow(concepts_df_tmp)){
    json_str <- concepts_df_tmp[i, "concept_set_expression"]
    parsed <- jsonlite::fromJSON(json_str, simplifyDataFrame = FALSE)
    for (i in 1:length(parsed)){
      conceptsToExclude <- c(conceptsToExclude, parsed[[i]]$concept$CONCEPT_CODE)
    }
  }
  return(as.integer(conceptsToExclude))
}




negative_cohort_generate <- function(connectionDetails,
                                     cohortDatabaseSchema,
                                     cohortTable){
  negativeControlIds <- read.csv("inst/settings/negativeControlOutcomes.csv")$outcome_concept_id
  negativeControlCohorts <- tibble(
    cohortId = negativeControlIds,
    cohortName = sprintf("Negative control %d", negativeControlIds),
    outcomeConceptId = negativeControlIds
  )
  cohortTableNames <- CohortGenerator::getCohortTableNames(cohortTable = cohortTable)
  CohortGenerator::generateNegativeControlOutcomeCohorts(connectionDetails = connectionDetails,
                                        cdmDatabaseSchema = cdmDatabaseSchema,
                                        cohortDatabaseSchema = cohortDatabaseSchema,
                                        cohortTableNames = cohortTableNames,
                                        negativeControlOutcomeCohortSet = negativeControlCohorts)
}
