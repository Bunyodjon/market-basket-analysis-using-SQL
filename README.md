# market-basket-analysis-using-SQL

## Hello,
## You might ask why did you implement market basket analysis in SQL when we can do this in R or Python with ready libraries? 
## My answer: I was not allowed to use other tools. I had to schedule this script after weekly dataload and we use only SQL agent job for scheduling. So I decided to do this within SQL environment based on business needs. It was a good challenge and eventually everyone was very happy with the output.  Note: this script might have deviated from classic market basket analysis based on what business analysts wanted to see. 

###  Definitions: Key metrics for association rules:

1)	Support: Percentage of orders that contain the item set. It is a measure of how frequently the collection of items
	occur together as a percentage of all transactions. For instance, there are 11 orders in total(by 
	different customers) and {bread, butter} occurs together in 3 of them. So, Support(Bread, Butter)=3/11. 

2)  Confidence: Given two items, X and Y, confidence measures the percentage of times that item Y is 
	purchased, given that item X was purchased. This is expressed as: Confidence(Y|X) = Freq(X, Y)/Freq(X)
	This does not tell there is a relationship between two items. The next matric is the one that can tell about it. 

3)	Lift:   Lift(X, Y) = Support(X,Y)/[Support(X) * Support (Y)] . Lift is the ratio of confidence to the expected confidence.
	It tells how much our confidence has increased that B will be purchased  given that A was purchased. 
	
	Lift=1 implies that there is no relationship between X and Y.
	Lift > 1 implies that there is a positive relationship between X and Y. 
	Lift < 1 implies that there is a negative relationship between X and Y. 
