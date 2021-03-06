extract.time <- function(data, timeorder) 
{
    x = data$x
    y = data$y
    if (length(timeorder) == 1) 
    {
        index = which(as.numeric(colnames(y)) == timeorder)
      	if(length(index) ==0)
      	{
      	    stop("timeorder must have the same names as the colnames of y")
      	}
    }
    if (length(timeorder) > 1) 
    {
	      index = vector("numeric", length(timeorder))
        for (i in 1:length(timeorder)) 
        {
            index[i] = which(as.numeric(colnames(y)) == timeorder[i])
        }
    }
    newdata = as.matrix(y[, index])
    colnames(newdata) = timeorder
    ftsdata = fts(x, newdata, start = as.numeric(colnames(y))[1], xname = data$xname, yname = data$yname)
    class(ftsdata) = class(data)
    return(ftsdata)
}
