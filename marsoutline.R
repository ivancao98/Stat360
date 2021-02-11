


library(rpart)

library(earth)


mars = function(formula, data, control)
{
  fwd.out = fwd_stepwise()
  
  bwd.out = bwd_stepwise(bwd.in = fwd.out)
  
  return(bwd.out)
}

mars.control = function()
{
  control = list()
  return(control)
}

fwd_stepwise = function()
{
  empt = list()
  return(empt)
}


bwd_stepwise = function(bwd.in)
{
  empt = list()
  return(empt)
}






