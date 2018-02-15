\name{runGenphen}



\alias{runGenphen}




\title{
Genetic association analysis using Bayesian inference and statistical learning
methods
}



\description{
Given a set of genotypes such as single nucleotide polymorphisms (SNPs) or
single amino acid polymorphisms (SAAPs) for a set of N individuals, and the
corresponding phenotypes, genphen computes two association scores between each
genotype and phenotypes. The first score is computed using Bayesian inference,
while the second score is estimated with random forest (RF).
}



\usage{
runGenphen(genotype, phenotype, phenotype.type, mcmc.chains,
           mcmc.iterations, mcmc.warmup, mcmc.cores, hdi.level,
           stat.learn.method, cv.iterations)
}


\arguments{
\item{genotype}{Character matrix/data frame or a vector, containing SNPs/SAAPs
as columns or alternatively as DNAMultipleAlignment or AAMultipleAlignment
Biostrings object.}
\item{phenotype}{Numerical vector for continuous-phenotype analysis, numerical
or character vector for dichotonous-phenotype analysis.}
\item{phenotype.type}{'continuous' or 'dichotomous' based on phenotype type.}
\item{mcmc.chains}{Number of MCMC chains used to test each association test.
We recomend mcmc.chains >= 2.}
\item{mcmc.iterations}{Length of MCMC chains (default = 1,000).}
\item{mcmc.warmup}{Length of adaptive MCMC chains (default = 500).}
\item{mcmc.cores}{Number of cores used for the MCMC (default = 1).}
\item{hdi.level}{Highest density interval (HDI) (default = 0.95).}
\item{stat.learn.method}{Character parameter used to specify the statistical
learning method used in the analysis. Currently two methods are available:
random forest ('rf') and support vector machine ('svm').}
\item{cv.iterations}{cross-validation iterations (default = 1,000).}
}



\details{
Input:
\itemize{
\item{genotype}
P genotypes of N individuals in the form of NxP character matrix/data frame or
vector (if P = 1).
\item{phenotype}
phenotypes of N individuals in the form of a N-sized vector. The type of the
phenotype can either be continuous or dichotomous. Therefore, genphen has two
analysis modes for each situation. The main difference between them is the
design of the Bayesian hierarchical model which are used.
}

Goal: To quantify the association between each genotype and phenotype. With
genphen, we provide two measures of association:
\itemize{
\item{Classification accuracy (CA): it is a metric obtained with a statistical
learning technique such as random forest (RF) or support vector machine (SVM),
and measures the degree of accuracy with which one can classify (predict) the
alleles of an SNP from the phenotype measurements. If there exists a strong
association between a particular SNP and the phenotype, one should be able to
build a statistical model which accurately classifies the two alleles of that
SNP solely from the phenotype data (CA approx. 1). Otherwise, the classification
accuracy of statistical model should be approximately similar to that of simple
guessing (CA approx. 0.5). Promising SNPs thus have a high CA close to 1.}

\item{Effect size: for each SNP we compute the effect size, i.e. the size of
the difference in phenotype observed between its alleles (amino acids in the
case of SAAP). Depending on the type of the phenotype, we either compute the
Cohen's d effect size for continuous phenotypes, or the absolute effect size
for dichotomous phenotypes. We first use Byesian inference to learn the
parameters of the distribution of the phenotype in each allele, and then plug
the posterior distribution of these parameters into the corresponding equations
for computing the effect size. In addition to the point estimates of the effect
sizes, we also estimate the corresponding highest density intervals (HDIs).}

The two association (CA and effect size) scores can be correlated, i.e. when
CA is close to 1, the effect size is large. This is not always the case, i.e.
we can have a small but significant effect size, yet a perfect CA. This is an
interesting information which could be lost if a single association metric was
used. Moreover, RF and SVM allow us to capture non-linear associations.
}
}

\value{
\bold{General parameters:}
\item{site}{id of the site (e.g. position in the provided sequence alignment)}
\item{mutation}{type of polymorphism (e.g. T->A)}
\item{data}{number of data points for each allele (e.g. A:10, T:20)}

\bold{Association score parameters:}
\item{cohens.d or absolute.d}{Cohen's d effect size (continuous phenotype
analysis) or absolute effect size (dichotomous phenotype analysis).
point estimate}
\item{cohens.d.L/cohens.d.H or absolute.d.L/absolute.d.H}{The highest density
interval (HDI) of the estimated effect size.}
\item{ca, ca.L, ca.H}{Classification accuracy (CA) estimate and its HDI}
\item{b.coef}{Bhattacharyya coefficient, overlap degree between the two
posterior predicted distributions of the phenotypes}

\bold{MCMC convergence parameters:}
\item{s, g, n}{s=site, g=genotype, n=number of observations}
\item{mu.rhat, sigma.rhat}{Potential scale reduction factor from the MCMC
simulation for each parameter}
\item{mu.ess, sigma.ess}{Effective sampling size from the MCMC simulation for
each parameter}
\item{divergence}{Indicator of occuring divergences during the MCMC simulation}
\item{treedepth}{Indicator of treedepth exceptions during the MCMC simulation}
}



\author{
  Simo Kitanovski <simo.kitanovski@uni-due.de>
}



\examples{
# I: Continuous phenotype analysis

# genotype inputs:
data(genotype.saap)
# phenotype inputs:
data(phenotype.saap)

# run genphen
continuous.analysis <- runGenphen(genotype = genotype.saap[, 1:3],
                                  phenotype = phenotype.saap,
                                  phenotype.type = "continuous",
                                  mcmc.chains = 2,
                                  mcmc.iterations = 2000,
                                  mcmc.warmup = 500,
                                  mcmc.cores = 2,
                                  hdi.level = 0.95,
                                  stat.learn.method = "rf",
                                  cv.iterations = 500)

# II: Dichotomous phenotype analysis

# genotype inputs:
data(genotype.saap)
# phenotype inputs:
data(dichotomous.phenotype.saap)

# run genphen
dichotomous.analysis <- runGenphen(genotype = genotype.saap[, 1:3],
                                   phenotype = dichotomous.phenotype.saap,
                                   phenotype.type = "dichotomous",
                                   mcmc.chains = 2,
                                   mcmc.iterations = 2000,
                                   mcmc.warmup = 500,
                                   mcmc.cores = 2,
                                   hdi.level = 0.95,
                                   stat.learn.method = "rf",
                                   cv.iterations = 500)
}


\seealso{
runDiagnostics
}