\name{runDiagnostics}



\alias{runDiagnostics}




\title{Data reduction procedure}



\description{
The methods implemented in genphen are statistically superior to the ones 
implemented by most classical (frequentist) tools for GWAS. A major challenge, 
however, of our method is the substantially increased computational cost when 
analyzing thousands of SNPs. Inspired by the biological assumption that the 
major fraction of the studied SNPs are non-informative (genetic noise) with
respect to the selected phenotype, various data reduction techniques can be 
implemented to quickly scan the SNP and discard a substantial portion of the 
the SNPs deemed to be clearly non-informative.
}

\usage{
runDiagnostics(genotype, phenotype, phenotype.type, rf.trees)
}



\arguments{
\item{genotype}{Character matrix/data frame or a vector, containing SNPs/SAAPs
as columns or alternatively as DNAMultipleAlignment or AAMultipleAlignment
Biostrings object.}
\item{phenotype}{Numerical vector.}
\item{phenotype.type}{Character indicator of the type of the phenotype, with
'Q' for a quantitative, or 'D' for a dichotomous phenotype.}
\item{rf.trees}{Number of random forest trees (default = 5,000).}
}




\details{
The data reduction procedure includes the following steps:
\enumerate{
\item The complete data (genotypes and a single phenotype) is used to train a 
random forest (RF) model, which will quantify the importance of each SNP/SAAP in 
explaining the phenotypeassociation between each SNP and the phenotype.
\item We can then plot the distribution of variable importances, to get an 
insight into the structure of the importances values and potentially disect the 
signal from the noise.
\item The main analysis can then be performed with runGenphen using a subset 
(based on their importance) of SNPs
}
}

\value{
\item{site}{id of the site (e.g. position in the provided sequence alignment)}
\item{importance}{Magnitude of importance (impurity) of the site, estimated 
with random forest implemented in R package ranger}
}


\author{
  Simo Kitanovski <simo.kitanovski@uni-due.de>
}



\examples{
# genotypes:
data(genotype.saap)
# quantitative phenotype:
data(phenotype.saap)

# run diagnostics
diag <- runDiagnostics(genotype = genotype.saap,
                       phenotype = phenotype.saap,
                       phenotype.type = "Q",
                       rf.trees = 5000)

}

\seealso{
runGenphen, runPhyloBiasCheck
}
