from python import Python

fn main() raises:
    print("Mojo SDK working")
    try:
        var sklearn = Python.import_module("sklearn")
        print("sklearn import success")
    except:
        print("sklearn import failed")

    var pd = Python.import_module("pandas")
    var sklearn_datasets = Python.import_module("sklearn.datasets")
    var data = sklearn_datasets.load_iris()
    
    # Check iris dataset
    print("Iris Dataset:")
    print(data.head())
    print()
