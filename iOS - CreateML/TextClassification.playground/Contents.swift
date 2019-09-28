import Foundation
import CreateML

let path = "/Users/user/Downloads/Samples"
let fileURL = URL(fileURLWithPath: "\(path)/spam.json")
let outputFileDirectory = URL(fileURLWithPath: "\(path)/SpamDetectV1")

// Support .csv & .json.
let data = try MLDataTable(contentsOf: fileURL)
print("Data size: \(data.size)")
// Random split training(8)/testing data(2).
let (trainingData, testingData) = data.randomSplit(by: 0.8)
let classifier = try MLTextClassifier(
    trainingData: trainingData,
    textColumn: "text",   // json.text
    labelColumn: "label") // json.label
let evaluation = classifier.evaluation(on: testingData)

// Accuracy = 1 - errorRate
let trainingAccuracy = (1.0 - classifier.trainingMetrics.classificationError) * 100
let validationAccuracy = (1.0 - classifier.validationMetrics.classificationError) * 100
let evaluationAccuracy = (1.0 - evaluation.classificationError) * 100

let metaData = MLModelMetadata(
    author: "Billy",
    shortDescription: "SpamDetect",
    license: nil,
    version: "1.1",
    additional: nil)

try classifier.write(to: outputFileDirectory, metadata: metaData)
