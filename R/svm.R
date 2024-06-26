library(e1071)

#' Support Vector Machine (SVM) Model
#'
#' Fits a support vector machine model using the e1071 package.
#'
#' @param data The dataset containing predictor variables and response variable.
#' @param importance Logical indicating whether to perform feature importance selection.
#' @param responseVariable The name of the response variable in the dataset.
#' @param kernel The type of kernel function to be used in the SVM.
#' @param type The type of SVM. "class" for classification and "eps-regression" for regression.
#' @param cost The cost parameter for the SVM.
#' @param gamma The kernel parameter for "radial", "polynomial", and "sigmoid" kernels.
#' @param epsilon The epsilon parameter for the SVM.
#' @param degree The degree of the polynomial kernel (only applicable if kernel = "polynomial").
#' @param coef0 The coef0 parameter for the "polynomial" and "sigmoid" kernels.
#' @param nfolds The number of folds for cross-validation.
#' @param k The number of important features to select.
#'
#' @return A list containing the fitted SVM model and selected features.
#' @export
#'
#' @examples
#' # Load the required library
#'library(e1071)

#'# Generate sample data
#'set.seed(123)
#'x <- matrix(rnorm(100), ncol = 5)
#'y <- as.factor(sample(0:1, 20, replace = TRUE))

#'# Create a dataset
#'data <- data.frame(x, y)

#'# Fit an SVM model
#'svm_model <- svmModel(data = data, importance = TRUE, responseVariable = "y", kernel = "radial", type = "class", cost = 1, gamma = 0.1, epsilon = 0.1, nfolds = 5, k = 3)

#'# Print the selected features
#'print(svm_model$selectedFeatures)

#'# Print the SVM model details
#'print(svm_model$fit)

#'# Make predictions if needed
#'# predictions <- predict(svm_model$fit, newdata = x_test)

svmModel = function(data, importance = FALSE,
                    responseVariable, kernel = "radial",
                    type = "default", cost = 1, gamma = NULL,
                    epsilon = 0.1, degree = 3, coef0 = 0,
                    nfolds = 10, k = 6
                    ) {
    if (!is.null(gamma) && !is.numeric(gamma)) {
        stop("gamma parameter must be numeric")
    }
    if(!is.null(importance) && !is.logical(importance)){
        stop("importance parameter accepts only 'logical' type values TRUE/FALSE")
    }
    if( !(kernel %in% c("linear", "radial", "polynomial", "sigmoid")) ){
        stop("Please provide a valid kernel type: ('linear', 'radial', 'polynomial', 'sigmoid')")
    }
    if(!is.null(epsilon) && !is.numeric(epsilon)){
        stop("epsilon parameter accepts only 'numeric' type values ")
    }
    if(!is.null(cost) && !is.numeric(cost)){
        stop("cost parameter accepts only 'numeric' type values ")
    }
    if(!is.null(coef0) && !is.numeric(coef0)){
        stop("coef0 parameter accepts only 'numeric' type values ")
    }
    if(!is.null(degree) &&!is.numeric(degree)){
        stop("degree parameter accepts only 'numeric' type values ")
    }

    if(!is.data.frame(data)){
        stop("data must be a dataframe")
    }
    if(!is.character(responseVariable)){
        stop("parameter 'responseVariable' must be a string")
    }
    if(importance && !is.numeric(k)){
        stop("parameter 'k' must be of type numeric")
    }
    if(!is.null(k) && k<1){
        stop("parameter 'k' must be >= 1.")
    }

    x = data[, !names(data) %in% responseVariable, drop = FALSE]
    y = data[, responseVariable, drop = FALSE]

    y_copy = as.matrix(y)

    svmType = "eps-regression"
    if ( type == "class") {
        y = as.factor(y_copy)
        svmType = "C-classification"
    }

    print(paste("svmType: ", svmType))

    # else{
    #     print("------")
    #     print(unique(y))
    #     y = data.frame(y)
    # }

    x = convertCatToNumeric(x, intercept = FALSE, toDataFrame = FALSE)
    x = x$data
    x_copy = x
    x = scale(x)

    # Convert target to factor for multinomial classification

    data = data.frame(x, y)

    # cat("class of x_copy: ", class(x_copy))
    # cat("class of y_copy: ", class(y_copy))

    if(ncol(x)>nrow(x)){
        print("p>>n setting importance = TRUE for selecting k most informative predictors.")
        importance = TRUE
        if(is.null(k)){
            warning("parameter 'k' is missing, setting it to default value : 6")
            k = 6
        }
    }

    if(importance){
        # cv.fit = crossValidation(x_copy, y_copy, alpha = 1, type = type, nfolds = nfolds)
        # print(cv.fit)
        # print(coef(cv.fit$fit))
        selected_vars = getKImportantPredictors(x, y, type = type, k = k )
        x = x[, selected_vars]
        data = data.frame(x, y)
        parameter_grid <- list(
            linear = expand.grid(cost = c(0.1, 1, 10)),
            polynomial = expand.grid(cost = c(0.1, 1, 10), degree = c(2, 3, 4)),
            radial = expand.grid(cost = 10^seq(-2, 1.5, by = 0.5)),
            sigmoid = expand.grid(cost = c(0.1, 1, 10), gamma = c(0.1, 1, 10), coef0 = c(0, 1, 2))
        )

        print(parameter_grid[[kernel]])


        tune.control = tune.control(sampling = "cross", cross = nfolds)
        # finalData = data.frame(data[, cv.fit$features], y)
        # finalData = data
        fit = tune(svm, y ~ ., data = data, kernel = kernel, tunecontrol = tune.control, ranges = parameter_grid[[kernel]], type = svmType)

        # return(list(fit = fit$best.model, selectedFeatures = colnames(data[, cv.fit$features])))
        return(list(fit = fit$best.model, selectedFeatures = colnames(data[, selected_vars])))
    }
    else{
        print(class(data$y))
        if (kernel == "linear") {
            fit <- svm(y ~ ., data = data, kernel = "linear", cost = cost, epsilon = epsilon, type = svmType)
        } else if (kernel == "radial") {
            if (is.null(gamma)) {
                fit <- svm(y ~ ., data = data, kernel = "radial", cost = cost, epsilon = epsilon, type = svmType)
            } else {
                fit <- svm(y ~ ., data = data, kernel = "radial", cost = cost, gamma = gamma, epsilon = epsilon, type = svmType)
            }
        } else if (kernel == "polynomial") {
            fit <- svm(y ~ ., data = data, kernel = "polynomial", cost = cost, degree = degree, coef0 = coef0, epsilon = epsilon, type = svmType)
        } else if (kernel == "sigmoid") {
            fit <- svm(y ~ ., data = data, kernel = "sigmoid", cost = cost, gamma = gamma, coef0 = coef0, epsilon = epsilon, type = svmType)
        }

        return(list(fit = fit, selectedFeatures = colnames(data[, -ncol(data)])))
    }

}

