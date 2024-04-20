# #
# Change the path
PATH = "C:/Users/coe16/Downloads/Mystery.csv"
df = read.csv(PATH)
#
set.seed(123)
trainID <- sample(1:nrow(df),round(0.75*nrow(df)))
trainData <- df[trainID,]
testData <- df[-trainID,]
#
#

# ===========================================
# Linear Regression
# ===========================================

# # formula1 = y ~ x1

# For no intercept form
# coefficients = linearRegression(y~x2, data = trainData, intercept = FALSE)
# print(coefficients)

# With intercept
coefficients = linearRegression(y~x2, data = trainData)
print(coefficients)
#
pred = predict_regression(coefficients = as.matrix(coefficients), newdata = as.matrix(testData$x2))
#
rmse(pred, testData$y)

# model1 = lm(y ~ 0 + x2, data = trainData) # For no intercept
model1 = lm(y ~ x2, data = trainData)
act <- predict(model1, subset(testData, select = x2))

rmse(act, testData$y)

#
# c3 = linearRegression(y ~ ., trainData, intercept = FALSE) # For no intercept
c3 = linearRegression(y ~ ., trainData)
c3

testSet = preprocessTestData(subset(testData, select = -y), intercept = FALSE)
# testSet = convertCatToNumeric(testSet)

pred = predict_regression(coefficients = c3, newdata = testSet)
#
rmse(pred, testData$y)

testData <- df[-trainID,]

# model2 = lm(y ~ 0 + ., data = trainData) # For no intercept term
model2 = lm(y ~ ., data = trainData)
act <- predict(model2, subset(testData, select = -y))

rmse(act, testData$y)

# ===========================================
# Ridge Regression
# ===========================================

lambda = 0.1
x = subset(trainData, select = -y)
y = subset(trainData, select = y)

model = ridgeRegression(x, y, lambda)

print(model)

testSet = preprocessTestData(subset(testData, select = -y))
# testSet = convertCatToNumeric(testSet)
# testSet = as.matrix(testSet)

pred = predict_regression(model, testSet)
#
library(glmnet)
x = model.matrix(y ~ ., data = trainData)[, -1]
y = trainData$y

# Using glmnet function to verify

ridge_ = glmnet(x,y, alpha = 0, lambda = lambda)
rmodel = coef(ridge_)
print(rmodel)
#

act <- testSet %*% rmodel

rmse(pred, testData$y)
rmse(act, testData$y)

# ===========================================
# Lasso Regression
# ===========================================

lambda = 0.1
x = model.matrix(y ~ ., data = trainData)[, -1]
y = trainData$y

# model = lassoRegression(x, y, lambda)
model = lassoRegression(subset(trainData, select = -y), trainData$y, lambda)

testSet = preprocessTestData(subset(testData, select = -y))

pred = predict_regression(model, testSet)

# Print the estimated coefficients
print(model)

library(MASS)
library(glmnet)
# Using glmnet function to verify
lasso_ <- glmnet(x,y, alpha = 1, lambda = lambda)

lmodel <- coef(lasso_)

print(lmodel)

act <- testSet %*% lmodel

rmse(pred, testData$y)
rmse(act, testData$y)

# ===========================================
# ElasticNet Regression
# ===========================================
lambda1 = 0.1
lambda2 = 0.2
model = elasticNet(subset(trainData, select = -y), trainData$y, lambda1, lambda2)
print(model)

testSet = preprocessTestData(subset(testData, select = -y))

pred = predict_regression(model, testSet)

# Print the estimated coefficients

library(MASS)
library(glmnet)
x = model.matrix(y ~ ., data = trainData)[, -1]
y = trainData$y

# Using glmnet function to verify
elastic_ <- glmnet(x,y, alpha = 0.5, lambda = lambda2)

emodel <- coef(elastic_)

print(emodel)

act <- testSet %*% lmodel

rmse(pred, testData$y)
rmse(act, testData$y)

# ===========================================
# vif
# ===========================================

set.seed(123)
n <- 100
x1 <- rnorm(n)
x2 <- rnorm(n)
x3 <- x1 + x2 + rnorm(n, sd = 0.2)
x4 <- rnorm(n)
x = cbind(x1, x2, x3, x4)
y <- x1 - x2 - x3 + x4 + rnorm(n)

data = data.frame(y, x)

model = lm(y ~ x1 + x2 + x3 + x4)

# model1 = lm(y ~ x)
model1 = lm(y ~ ., data = data)

res = custom_vif2(model1)
res

PATH = "C:/Users/coe16/Downloads/math.csv"
df = read.csv(PATH, sep = ";")
df = subset(df, select = -c(G1, G2))
df = preprocessTestData(df, intercept = FALSE)
sum(is.na(df))

head(df)
str(df)

set.seed(123)
trainID <- sample(1:nrow(df),round(0.75*nrow(df)))
trainData <- data.frame(df[trainID,])
testData <- data.frame(df[-trainID,])

x = as.matrix(subset(trainData, select = -G3))
y = as.matrix(trainData$G3)

x_test = as.matrix(subset(testData, select = -G3))
y_test = as.matrix(testData$G3)

model = lm()