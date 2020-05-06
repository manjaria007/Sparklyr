#Install required packages

install.packages("corrr")
install.packages("dbplot")
install.packages("rmarkdown")
install.packages("sparklyr")
library(sparklyr)
library(dplyr)
library(ggplot2)

#Install Spark
spark_install("2.3")
sc <- spark_connect(master = "local", version = "2.3")

#Importing Data
cars <- copy_to(sc, mtcars)

head(cars)

#Data Wrangling - Transforms data into another format to make it more appropriate for analysis
#below code will provide means for all columns
summarize_all(cars, mean, na.rm = TRUE)

summarize_all(cars, mean, na.rm = TRUE) %>%
  show_query()

#explode function to separate sparks array value results into their own record
#Utilized explode() within mutate() command and pass the variable containing the results of
#percentile operation:

summarise(cars, mpg_percentile = percentile(mpg, array(0.25, 0.5, 0.75))) %>%
  mutate(mpg_percentile = explode(mpg_percentile))



#Correlation:

##Exploring data using correlation and then visualizing it
## It will helps us to find out what kind of statistical relationship exists between paired
## sets of variables.

##Here spark provides a function to correlate across entire dataset and return result in
##DataFrame

ml_corr(cars)


##Corrr R package specializes in correlations
library(corrr)
correlate(cars, use = "pairwise.complete.obs", method = "pearson")


#shave function turns all duplicated results into NAs
correlate(cars, use = "pairwise.complete.obs", method = "pearson") %>%
  shave() %>%
  rplot()  

#Size of the cirles indicates that how significant their relationship is. 

##Visualize
ggplot(aes(as.factor(cyl), mpg), data = mtcars) + geom_col()
##Mtcars data was automatically transformed into 3 discrete aggregated numbers.
#Each result was mapped into an x and y

##Distribution of cars miles per gallon
ggplot(cars, aes(mpg)) +
  geom_histogram(binwidth = 4) + xlab('MPG') + ylab('#ofcars') +
  ggtitle('Distribution of cars by mileage')

#DBplot
##analyzing mpg using histogram
library(dbplot)
cars %>%
  dbplot_histogram(mpg, binwidth = 3) +
  labs(title = "MPG Distribution",
       subtitle = "Histogram over miles per gallon")


##ggplot
#Utilized Scatter plot to compare the relationship b/w 2continuous variable
##It will display the relationship between the weight of car and its gas consumption
ggplot(aes(mpg, wt), data = mtcars) + 
  geom_point()
##The plot shows that the higher the weight, the higher the gas consumption
##as the dot are in line from upper left to lower right



##Linear regression model against all features
##predict miles per gallon

cars %>%
  ml_linear_regression(mpg ~ .) %>%
  summary()

##Experimenting with different features

cars %>%
  ml_linear_regression(mpg ~ hp + cyl) %>%
  summary()
  