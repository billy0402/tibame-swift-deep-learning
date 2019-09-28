import Foundation
import CreateML

let path = "/Users/user/Downloads/Samples"
let fileURL = URL(fileURLWithPath: "\(path)/HouseData.csv")
let outputFileDirectory = URL(fileURLWithPath: "\(path)/HousePriceV1")

// Support .csv & .json.
let data = try MLDataTable(contentsOf: fileURL)
print("Data size: \(data.size)")
// Random split training(8)/testing data(2).
let (trainingData, testingData) = data.randomSplit(by: 0.8)
let regressor = try MLRegressor(trainingData: trainingData, targetColumn: "MEDV")

let metaData = MLModelMetadata(
    author: "Billy",
    shortDescription: "HousePrice",
    license: nil,
    version: "1.1",
    additional: nil)

try regressor.write(to: outputFileDirectory, metadata: metaData)
