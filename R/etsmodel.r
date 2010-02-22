etsmodel = function (y, errortype, trendtype, seasontype, damped, alpha = NULL,
    beta = NULL, gamma = NULL, phi = NULL, lower, upper, opt.crit,
    nmse, bounds)
{
    par <- initparam(alpha, beta, gamma, phi, trendtype, seasontype,
        damped, lower, upper)
    names(alpha) <- names(beta) <- names(gamma) <- names(phi) <- NULL
    par.noopt <- c(alpha = alpha, beta = beta, gamma = gamma,
        phi = phi)
    if (!is.null(par.noopt))
        par.noopt <- c(na.omit(par.noopt))
    if (!is.na(par["alpha"]))
        alpha <- par["alpha"]
    if (!is.na(par["beta"]))
        beta <- par["beta"]
    if (!is.na(par["gamma"]))
        gamma <- par["gamma"]
    if (!is.na(par["phi"]))
        phi <- par["phi"]
    tsp.y <- tsp(y)
    if (is.null(tsp.y))
        tsp.y <- c(1, length(y), 1)
    m <- tsp.y[3]
    if (!check.param(alpha, beta, gamma, phi, lower, upper, bounds,
        m)) {
        print(paste("Model: ETS(", errortype, ",", trendtype,
            ifelse(damped, "d", ""), ",", seasontype, ")", sep = ""))
        stop("Parameters out of range")
    }
    init.state <- initstate(y, trendtype, seasontype)
    nstate <- length(init.state)
    par <- c(par, init.state)
    lower <- c(lower, rep(-Inf, nstate))
    upper <- c(upper, rep(Inf, nstate))
    np <- length(par)
    if (np >= length(y) - 1)
        return(list(aic = Inf, bic = Inf, aicc = Inf, mse = Inf,
            amse = Inf, fit = NULL, par = par, states = init.state))
    if (length(par) == 1)
        tmp <- options(warn = -1)$warn
    fred <- optim(par, lik, method = "Nelder-Mead", y = y, nstate = nstate,
        errortype = errortype, trendtype = trendtype, seasontype = seasontype,
        damped = damped, par.noopt = par.noopt, lowerb = lower,
        upperb = upper, opt.crit = opt.crit, nmse = nmse, bounds = bounds,
        m = m, pnames = names(par), pnames2 = names(par.noopt),
        control = list(maxit = 2000))
    fit.par <- fred$par
    names(fit.par) <- names(par)
    if (length(par) == 1)
        options(warn = tmp)
    init.state <- fit.par[(np - nstate + 1):np]
    if (seasontype != "N")
        init.state <- c(init.state, m * (seasontype == "M") -
            sum(init.state[(2 + (trendtype != "N")):nstate]))
    if (!is.na(fit.par["alpha"]))
        alpha <- fit.par["alpha"]
    if (!is.na(fit.par["beta"]))
        beta <- fit.par["beta"]
    if (!is.na(fit.par["gamma"]))
        gamma <- fit.par["gamma"]
    if (!is.na(fit.par["phi"]))
        phi <- fit.par["phi"]
    e <- pegelsresid.C(y, frequency(y), init.state, errortype,
        trendtype, seasontype, damped, alpha, beta, gamma, phi)
    n <- length(y)
    aic <- e$lik + 2 * np
    bic <- e$lik + log(n) * np
    aicc <- e$lik + 2 * n * np/(n - np - 1)
    mse <- e$amse[1]
    amse <- mean(e$amse[1:nmse])
    states = ts(e$states, f = m, s = tsp.y[1] - 1/m)
    colnames(states)[1] <- "l"
    if (trendtype != "N")
        colnames(states)[2] <- "b"
    if (seasontype != "N")
        colnames(states)[(2 + (trendtype != "N")):ncol(states)] <- paste("s",
            1:m, sep = "")
    tmp <- c("alpha", rep("beta", trendtype != "N"), rep("gamma",
        seasontype != "N"), rep("phi", damped))
    fit.par <- c(fit.par, par.noopt)
    if (errortype == "A")
        fits <- y - e$e
    else fits <- y/(1 + e$e)
    return(list(loglik = -0.5 * e$lik, aic = aic, bic = bic,
           aicc = aicc, mse = mse, amse = amse, fit = fred, residuals = ts(e$e,
            f = m, s = tsp.y[1]), fitted = ts(fits, f = m, s = tsp.y[1]),
             states = states, par = fit.par))
}
