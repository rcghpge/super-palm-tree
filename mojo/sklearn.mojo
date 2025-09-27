
# Scikit-learn in Mojo Example
"""
This Scikit-Learn model is not fine-tuned or robustly built. It is an example prototype build for 
ML/DL in the Mojo programming language.
"""

from collections.dict import Dict
from collections.list import List
from python import Python, PythonObject


fn generate_models() raises:
    # Import Packages/Libraries
    var pd = Python.import_module("pandas")
    var sklearn_datasets = Python.import_module("sklearn.datasets")

    # Load the Iris dataset
    var iris = sklearn_datasets.load_iris()
    var data = pd.DataFrame(data=iris["data"], columns=iris["feature_names"])
    data["target"] = iris["target"]

    # Display the first few rows of the dataset
    print("Iris Dataset:")
    print(data.head())
    print()

    var sklearn_models = Python.import_module("sklearn.model_selection")

    # Split the data into training and testing sets
    var X = data.drop("target", axis=1)
    var y = data["target"]

    var train_test_split = sklearn_models.train_test_split
    var split_result = train_test_split(X, y, test_size=0.2, random_state=42)

    var X_train = split_result[0]
    var X_test = split_result[1]
    var y_train = split_result[2]
    var y_test = split_result[3]

    # X_train, X_test, y_train, y_test are now PythonObjects representing your split data
    print("Train Test Split:")
    print("Training set shape:", X_train.shape)
    print("Testing set shape:", X_test.shape)
    print()

    # Generate Models
    # Linear Regression
    var lr = Python.import_module("sklearn.linear_model")

    # Initialize the model
    var model1 = lr.LinearRegression()

    # Train the model
    model1.fit(X_train, y_train)

    # Make predictions
    var predictions = model1.predict(X_test)

    # Decision Trees
    var dt = Python.import_module("sklearn.tree")

    # Initialize the model
    var model2 = dt.DecisionTreeClassifier()

    # Train the model
    model2.fit(X_train, y_train)

    # Make predictions
    predictions2 = model2.predict(X_test)

    # Model Evaluations
    # Linear Regression Model
    var metrics = Python.import_module("sklearn.metrics")

    # Linear Regression Metrics
    var mse = metrics.mean_squared_error(y_test, predictions)
    var r2 = metrics.r2_score(y_test, predictions)

    print("Linear Regression Model 1:")
    print("Mean Squared Error:", mse)
    print("R-squared:", r2)
    print()

    # Decision Tree Metrics
    var accuracy = metrics.accuracy_score(y_test, predictions2)
    var report = metrics.classification_report(y_test, predictions2)

    print("Decision Tree Model 2:")
    print("Accuracy:", accuracy)
    print("Classification Report:\n", report)

    # Hyperparameter Tuning (Decision Tree Model 3)
    var dt2 = Python.import_module("sklearn.tree")
    var grid_search = Python.import_module("sklearn.model_selection")

    # Define parameter grid
    # var pymax = Python.import_module("max.python").attr("Python")
    var param_grid = Python.dict()

    param_grid["criterion"] = Python.evaluate('["gini", "entropy"]')
    param_grid["max_depth"] = Python.evaluate("[None, 10, 20, 30]")

    # Initialize Decision Tree Model 3 with GridSearchCV
    var model3 = dt2.DecisionTreeClassifier()
    var tune = grid_search.GridSearchCV(
        dt2.DecisionTreeClassifier(), param_grid, cv=5
    )

    # Fine-tuning, training, and fitting the model with GridSearchCV
    model3 = tune.fit(X_train, y_train)

    # Print the best parameters
    print("Hyperparameter Tuning:")
    print("Best parameters:", model3.best_params_)


# Run Scikit-learn models
fn main() raises:
    generate_models()

# Example usage:
# mojo sklearn.mojo
# Or run
# pixi run mojo sklearn.mojo
