import Foundation
import CreateML
import CreateMLUI

//CreateML using Live View.
//let builder = MLImageClassifierBuilder()
//builder.showInLiveView()

//CreateML using code.
let path = "/Users/user/Downloads/Samples"
let trainingDirectory = URL(fileURLWithPath: "\(path)/Pets-100")
let testingDirectory = URL(fileURLWithPath: "\(path)/Pets-Testing")
let outputFileDirectory = URL(fileURLWithPath: "\(path)/PetClassifierV2")

var parameters = MLImageClassifier.ModelParameters()
parameters.maxIterations = 20

//.labeledDirectories(at: trainingDirectory) -> /Dog/0.jpg
//.labeledFiles(at: trainingDirectory)       -> /Dog.0.jpg
let model = try MLImageClassifier(trainingData: .labeledDirectories(at: trainingDirectory), parameters: parameters)
let evulation = try MLImageClassifier(trainingData: .labeledDirectories(at: testingDirectory))

let metaData = MLModelMetadata(
    author: "Billy",
    shortDescription: "Pets-100",
    license: nil,
    version: "1.1",
    additional: nil)

try model.write(to: outputFileDirectory, metadata: metaData)
