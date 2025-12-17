"""
Scikit-Learn in Mojo with Enhanced Debugging
Prototype with try-except and stack trace support for Mojo nightly.
"""

from collections.dict import Dict
from collections.list import List
from python import Python, PythonObject

fn safe_import(module_name: String) raises -> PythonObject:
    try:
        return Python.import_module(module_name)
    except e:
        print("Import failed for", module_name, ":", e)
        print("Stack trace:", String(e.get_stack_trace()))
        raise e

fn safe_evaluate(code: String) raises -> PythonObject:
    try:
        return Python.evaluate(code)
    except e:
        print("Python.evaluate failed for code:", code[:50], "... :", e)
        print("Stack trace:", String(e.get_stack_trace()))
        raise e

fn generate_models() raises:
    try:
        # Safe imports
        var pd = safe_import("pandas")
        var sklearn_datasets = safe_import("sklearn.datasets").load_iris()
        var sklearn_models = safe_import("sklearn.model_selection")
        var lr = safe_import("sklearn.linear_model")
        var dt = safe_import("sklearn.tree")
        var metrics = safe_import("sklearn.metrics")
        var grid_search = safe_import("sklearn.model_selection")
        
        # Load and prepare data
        var X = safe_evaluate("iris = __import__('sklearn.datasets').load_iris(); iris['data']")
        var y = safe_evaluate("iris = __import__('sklearn.datasets').load_iris(); iris['target']")
        var feature_names = safe_evaluate("iris = __import__('sklearn.datasets').load_iris(); iris['feature_names']")
        
        var data = pd.DataFrame(data=X, columns=feature_names)
        print("Iris Dataset:")
        print(data.head())
        print()
        
        # Train/test split
        var test_size = safe_evaluate("0.2")
        var random_state = safe_evaluate("42")
        var split_result = sklearn_models.train_test_split(X, y, test_size, random_state)
        var X_train = split_result[0]
        var X_test = split_result[1]
        var y_train = split_result[2]
        var y_test = split_result[3]
        
        print("Train Test Split:")
        print("Training set shape:", X_train.shape)
        print("Testing set shape:", X_test.shape)
        print()
        
        # Linear Regression (Model 1)
        try:
            var model1 = lr.LinearRegression()
            model1.fit(X_train, y_train)
            var predictions = model1.predict(X_test)
            
            var mse = metrics.mean_squared_error(y_test, predictions)
            var r2 = metrics.r2_score(y_test, predictions)
            print("Linear Regression Model 1:")
            print("Mean Squared Error:", mse)
            print("R-squared:", r2)
            print()
        except e:
            print("Linear Regression failed:", e)
            print("Stack trace:", String(e.get_stack_trace()))
        
        # Decision Tree (Model 2)
        try:
            var model2 = dt.DecisionTreeClassifier()
            model2.fit(X_train, y_train)
            var predictions2 = model2.predict(X_test)
            
            var accuracy = metrics.accuracy_score(y_test, predictions2)
            var report = metrics.classification_report(y_test, predictions2)
            print("Decision Tree Model 2:")
            print("Accuracy:", accuracy)
            print("Classification Report:\n", report)
            print()
        except e:
            print("Decision Tree failed:", e)
            print("Stack trace:", String(e.get_stack_trace()))
        
        # Hyperparameter Tuning (Model 3)
        try:
            var dt2 = safe_import("sklearn.tree")
            var param_grid = safe_evaluate("{'criterion': ['gini', 'entropy'], 'max_depth': [None, 10, 20, 30]}")
            var tune = grid_search.GridSearchCV(dt2.DecisionTreeClassifier(), param_grid, cv=safe_evaluate("5"))
            var model3 = tune.fit(X_train, y_train)
            
            print("Hyperparameter Tuning:")
            print("Best parameters:", model3.best_params_)
        except e:
            print("Hyperparameter tuning failed:", e)
            print("Stack trace:", String(e.get_stack_trace()))
    
    except e:
        print("generate_models outer error:", e)
        print("Full stack trace:", String(e.get_stack_trace()))
        raise e

fn main() raises:
    try:
        generate_models()
        print("All models completed successfully!")
    except e:
        print("Main caught fatal error:", e)
        print("Final stack trace:", String(e.get_stack_trace()))
        print("Exit code: 1")  # Status only, no return value

