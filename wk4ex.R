---
  title: "Week 4 exercises"

---
  
  ```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

## Short exercises based on chapters from text

1. Explain the output of the following code chunk.

```{r}
f <- function() {
  fe <- environment(f)
  ee <- environment()
  pe <- parent.env(ee)
  list(fe=fe,ee=ee,pe=pe)
}
f()
```

2. Read the help files on the `exists()` and
`get()` functions.
Explain the output of the following code chunk.

```{r}
f <- function(xx) {
  xx_parent <- if(exists("xx",envir=environment(f))) {
    get("xx",environment(f))
  } else {
    NULL
  }
  list(xx,xx_parent)
}
f(2)
xx <- 1
f(2)
rm(xx)
```

3. Write a function with argument `xx` that tests 
whether `xx` exists in the parent environment and, if so,
(a) assigns the value of `xx` in the parent environment
to the variable `xx_parent`, and
(b) tests whether `xx` and `xx_parent` are equal. If 
the test is FALSE, throw a warning to alert the user to
the fact that the two are not equal.

4. Write an infix version of `c()` that concatenates
two vectors.

## Recursive partitioning

* The following code chunk is the start of an implementation
of recursive partitioning using a binary tree data structure
to store the partition.
* Binary trees can be implemented as a linked list of nodes that
contain 
1. data
2. a pointer to the left child
3. a pointer to the right child
* For our recursive partitioning example, the data will be 
a region of the original covariate space and the response/covariate data
in that region.
* The following code chunk establishes node and region data structure.

```{r}
# Constructor for the node data structure:
new_node <- function(data,childl=NULL,childr=NULL){
  nn <- list(data=data,childl=childl,childr=childr)
  class(nn) <- "node"
  return(nn)
}
# The data stored in the node are a partition, or region of the 
# covariate space. Constructor for region data structure:
new_region <- function(coords=NULL,x,y){
  if(is.null(coords)) {
    coords <- sapply(x,range)
  }
  out <- list(coords=coords,x=x,y=y)
  class(out) <- "region"
  return(out)
}
```

# Some tests of the above constructors are given in the next code chunk.

```{r}
set.seed(123); n <- 10
x <- data.frame(x1=rnorm(n),x2=rnorm(n))
y <- rnorm(n)
new_region(x=x,y=y)
new_node(new_region(x=x,y=y))
```


```{r}
#---------------------------------------------------#
# Recursive partitioning function.
recpart <- function(x,y){
  init <- new_node(new_region(x=x,y=y))
  tree <- recpart_recursive(init)
  class(tree) <- c("tree",class(tree))
  return(tree)
}
recpart_recursive <- function(node) {
  R <- node$data
  # stop recursion if region has a single data point
  if(length(R$y) == 1) { return(NULL) }
  # else find a split that minimizes a LOF criterion
  # Initialize
  lof_best  <- Inf
  # Loop over variables and splits
  for(v in 1:ncol(R$x)){ 
    tt <- split_points(R$x[,v]) # Exercise: write split_points()
    for(t in tt) { 
      gdat <- data.frame(y=R$y,x=as.numeric(R$x[,v] <= t))
      lof <- LOF(y~.,gdat) # Exercise: write LOF()
      if(lof < lof_best) { 
        lof_best <- lof
        childRs <- split(R,xvar=v,spt=t) # Exercises: write split.region()
      }
    }
  } 
  # Call self on best split
  node$childl <- recpart_recursive(new_node(childRs$Rl))
  node$childr <- recpart_recursive(new_node(childRs$Rr))
  return(node)
  
  
  
}


split_points = function(vector)
{
  sorted = unique(sort(vector))
  trimmed.vec = sorted[sorted < max(sorted)]
  return(trimmed.vec)
}

LOF = function(formula, df)
{
  linmod = lm(formula, data = df)
  residsumsq = sum(resid(linmod)^2)
  return(residsumsq)
}


split.region <- function(R,xvar,spt){
  r1_ind <- (R$x[,xvar] <= spt)
  c1 <- c2 <- R$coords
  c1[2,xvar] <- spt; c2[1,xvar] <- spt 
  Rl <- new_region(c1,R$x[r1_ind,,drop=FALSE],R$y[r1_ind])
  Rr <- new_region(c2,R$x[!r1_ind,,drop=FALSE],R$y[!r1_ind])
  return(list(Rl=Rl,Rr=Rr))
}

print.region <- function(R,print.data=FALSE){
  cat("coordinates:\n")
  print(R$coords)
  if(print.data) {
    cat("y:\n")
    print(R$y)
    cat("x:\n")
    print(R$x)
  }
}

plot_regions.tree <- function(tree){
  # set up empty plot
  plot(tree$data$x[,1],tree$data$x[,2],xlab="X1",ylab="X2") 
  plot_regions.node(tree$childl)
  plot_regions.node(tree$childr)
}
# lines to outline a region in its first two dimensions
plot_regions.node<- function(node) {
  if(is.null(node)) return(NULL)
  x <- node$data$coords[,1]
  y <- node$data$coords[,2]
  lines(c(x[1],x[2],x[2],x[1],x[1]),c(y[1],y[1],y[2],y[2],y[1]),
        col="red")
  plot_regions.node(node$childl)
  plot_regions.node(node$childr)
}

set.seed(123); n <- 10
x <- data.frame(x1=rnorm(n),x2=rnorm(n))
y <- rnorm(n)
 mytree <- recpart(x,y)
 
 
 
 
```

## Exercises

1. Write `split_points()`. The function should take 
a vector of covariate values as input and return the sorted 
unique values.  You will need to trim off the maximum unique value, 
because this can't be used as a split point. (As yourself why not.)
Write a snippet of R code that tests your function.
2. Write the function `LOF()` that returns the lack-of-fit criterion
for a model. The function should take a model formula and
data frame as input, pass these to `lm()` and return the
residual sum of squares. 
Write a snippet of R code that tests your function.
3. Write `split.region()`. The function should take a
region `R`, the variable to split on, `v`, and the split point, `t`,
as arguments. Split the region into left and right 
partitions and return a list of two regions labelled
`Rl` and `Rr`. Note: It is tempting to split the x and y data
and calculate the coordinates matrix from the x's, as the constructor
does when not passed a coordinates matrix. However, this will
leave gaps in the covariate space. (Ask yourself why.)
Write a snippet of R code that tests your function.
4. Run `recpart()` with your versions of `split_points()`,
`LOF()` and `split.region()`. Use the test data `x` and `y` 
defined in the testing code chunk. At this point you do
not need to check that the output is correct; you will get 
a chance to to that in lab 2.
