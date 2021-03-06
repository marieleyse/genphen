



runGenphen <- function(genotype,
                       phenotype,
                       phenotype.type,
                       model.type,
                       mcmc.chains = 2,
                       mcmc.steps = 2500,
                       mcmc.warmup = 500,
                       cores = 1,
                       hdi.level = 0.95,
                       stat.learn.method = "rf",
                       cv.steps = 1000,
                       ...) {
  
  
  # check optional (dot) inputs
  dot.param <- checkDotParameters(...)
  
  
  # check inputs
  checkInput(genotype = genotype,
             phenotype = phenotype,
             phenotype.type = phenotype.type,
             model.type = model.type,
             mcmc.chains = mcmc.chains,
             mcmc.steps = mcmc.steps,
             mcmc.warmup = mcmc.warmup,
             cores = cores,
             hdi.level = hdi.level,
             stat.learn.method = stat.learn.method,
             cv.steps = cv.steps)
  
  
  # TODO: test
  # convert input data to stan data
  genphen.data <- getStanData(genotype = genotype,
                              phenotype = phenotype,
                              phenotype.type = phenotype.type)
  
  
  # TODO: needed anymore?
  if(is.null(genphen.data)) {
    stop("No genphen input data found.")
  }
  
  
  cat("======== Model Compilation ======== \n")
  rstan::rstan_options(auto_write = TRUE)
  if(model.type == "hierarchical") {
    model.file <- system.file("extdata", "H.stan", package = "genphen")
    model.stan <- rstan::stan_model(file = model.file, auto_write = TRUE)
  }
  if(model.type == "univariate") {
    model.file <- system.file("extdata", "U.stan", package = "genphen")
    model.stan <- rstan::stan_model(file = model.file, auto_write = TRUE)
  }
  
  
  cat("======== Bayesian Inference ======== \n")
  p <- runBayesianInference(genphen.data = genphen.data,
                            mcmc.chains = mcmc.chains,
                            mcmc.steps = mcmc.steps,
                            mcmc.warmup = mcmc.warmup,
                            cores = cores,
                            model.stan = model.stan,
                            adapt_delta = dot.param$adapt_delta,
                            max_treedepth = dot.param$max_treedepth,
                            refresh = dot.param$refresh,
                            verbose = dot.param$verbose)
  
  
  cat("======== Statistical Learning ======== \n")
  s <- runStatLearn(genphen.data = genphen.data,
                    method = stat.learn.method,
                    cv.fold = dot.param[["cv.fold"]],
                    cv.steps = cv.steps,
                    ntree = dot.param[["ntree"]],
                    hdi.level = hdi.level,
                    cores = cores)
  
  
  
  
  o <- getScores(p = p, s = s$results, 
                 hdi.level = hdi.level, 
                 genphen.data = genphen.data)
  
  
  # format scores
  o <- do.call(rbind, o)
  o <- o[, c("site", "ref", "alt", "refN", "altN", "p", "mean", 
             "se_mean", "sd", "X2.5.", "X97.5.", "n_eff", "Rhat", 
             "ca", "ca.L", "ca.H", "k", "k.L", "k.H")]
  colnames(o) <- c("site", "ref", "alt", "refN", "altN", "phenotype.id", 
                   "beta.mean", "beta.se", "beta.sd", "beta.hdi.low", 
                   "beta.hdi.high", "Neff", "Rhat", 
                   "ca.mean", "ca.hdi.low", "ca.hdi.high", 
                   "kappa.mean", "kappa.hdi.low", "kappa.hdi.high")
  
  
  
  cat("======== Pareto Optimization ======== \n")
  o <- getParetoScores(scores = o)
  
  
  
  # ppc
  cat("======== Posterior Prediction ======== \n")
  ppc <- getPpc(posterior = p$posterior, 
                genphen.data = genphen.data,
                hdi.level = hdi.level)
  
  
  return (list(scores = o, 
               ppc = ppc,
               complete.posterior = p$posterior))
}



# Description:
# Compute importance of each genotype
runDiagnostics <- function(genotype,
                           phenotype,
                           phenotype.type,
                           rf.trees = 5000) {
  
  
  # check input diagnostics
  checkDiagnosticInput(genotype = genotype, 
                       phenotype = phenotype, 
                       phenotype.type = phenotype.type, 
                       rf.trees = rf.trees)
  
  
  # convert input data to stan data
  genphen.data <- getStanData(genotype = genotype,
                              phenotype = phenotype,
                              phenotype.type = phenotype.type)
  
  
  # create genphen data
  rf.data <- as.data.frame(genphen.data$genotype)
  rf.data$Y <- genphen.data$Y[, 1]
  if(phenotype.type == "D") {
    rf.data$Y <- as.factor(rf.data$Y)
  }
  
  
  # ranger: importance dataset
  cat("======== RF diagnostics ======== \n")
  rf.out <- ranger::ranger(dependent.variable.name = "Y",
                           importance = "impurity",
                           data = rf.data, 
                           num.trees = rf.trees)
  
  
  rf.out <- data.frame(site = 1:length(rf.out$variable.importance),
                       importance = rf.out$variable.importance,
                       stringsAsFactors = FALSE)
  
  
  return (rf.out)
}




runPhyloBiasCheck <- function(input.kinship.matrix,
                              genotype) {
  
  
  # check params
  checkInputPhyloBias(input.kinship.matrix = input.kinship.matrix,
                      genotype = genotype)
  
  
  # convert input data to phylo data
  phylo.data <- getPhyloData(genotype = genotype)


  # compute kinship if needed
  if(is.null(input.kinship.matrix) | missing(input.kinship.matrix)) {
    kinship.matrix <- e1071::hamming.distance(genotype)
  }
  else {
    kinship.matrix <- input.kinship.matrix
  }
  
  # compute bias
  bias <- getPhyloBias(genotype = genotype, 
                       k.matrix = kinship.matrix)
  
  # bias = 1-dist(feature)/dist(total)
  bias$bias <- 1-bias$feature.dist/bias$total.dist

    
  # append bias to each SNP
  phylo.data$bias.ref <- NA
  phylo.data$bias.alt <- NA
  phylo.data$bias <- NA
  for(i in 1:nrow(phylo.data)) {
    bias.ref <- bias[bias$site == phylo.data$site[i] & 
                       bias$genotype == phylo.data$ref[i], ]
    bias.alt <- bias[bias$site == phylo.data$site[i] & 
                      bias$genotype == phylo.data$alt[i], ]
    phylo.data$bias.ref[i] <- bias.ref$bias[1]
    phylo.data$bias.alt[i] <- bias.alt$bias[1]
    phylo.data$bias[i] <- max(bias.ref$bias[1], bias.alt$bias[1])
  }
  
  
  # sort by site
  bias <- phylo.data[, c("site", "ref", "alt", "bias.ref", "bias.alt", "bias")]
  bias <- bias[order(bias$site, decreasing = FALSE), ]
  
  return (list(bias = bias, kinship.matrix = kinship.matrix))
}


