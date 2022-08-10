@description('Specifies the name of the Azure Machine Learning workspace where job will be created')
param existingWorkspaceName string

@description('Specifies the name of the Azure Machine Learning compute instance/cluster on which job will be run')
param existingComputeName string

@description('Specifies the name of the Azure Machine Learning experiment under which job will be created')
param experimentName string

@description('Specifies the name of the Azure Machine Learning job to be created')
param jobName string

@description('Specifies execution contraints for the job')
param limitSettings object = {
  maxTrials: 5
  maxConcurrentTrials: 1
  maxCoresPerTrial: -1
  enableEarlyTermination: true
  timeout: 'PT10H'
  trialTimeout: 'PT20M'
}

@description('Specifies training related configuration for the job')
param trainingSettings object = {
  blockedTrainingAlgorithms: [
    'LogisticRegression'
  ]
  enableModelExplainability: true
  enableOnnxCompatibleModels: false
  enableStackEnsemble: true
  enableVoteEnsemble: true
  ensembleModelDownloadTimeout: 'PT5M'
  enableDnnTraining: false
}

var compute = resourceId('Microsoft.MachineLearningServices/workspaces/computes', existingWorkspaceName, existingComputeName)

resource workspaceName_jobName 'Microsoft.MachineLearningServices/workspaces/jobs@2022-06-01-preview' = {
  name: '${existingWorkspaceName}/${jobName}'
  properties: {
    jobType: 'AutoML'
    tags: {
      ref: 'https://github.com/Azure/azureml-examples/blob/main/sdk/jobs/automl-standalone-jobs/automl-classification-task-bankmarketing'
    }
    experimentName: experimentName
    computeId: compute
    taskDetails: {
      logVerbosity: 'Info'
      taskType: 'Classification'
      primaryMetric: 'Accuracy'
      targetColumnName: 'y'
      trainingData: {
        uri: 'https://raw.githubusercontent.com/Azure/azureml-examples/main/sdk/jobs/automl-standalone-jobs/automl-classification-task-bankmarketing/data/training-mltable-folder/'
        jobInputType: 'MLTable'
      }
      validationData: {
        uri: 'https://raw.githubusercontent.com/Azure/azureml-examples/main/sdk/jobs/automl-standalone-jobs/automl-classification-task-bankmarketing/data/validation-mltable-folder/'
        jobInputType: 'MLTable'
      }
      featurizationSettings: {
        mode: 'auto'
      }
      limitSettings: limitSettings
      trainingSettings: trainingSettings
    }
  }
}

output Job_Studio_Endpoint string = workspaceName_jobName.properties.services.Studio.endpoint
