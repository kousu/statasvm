
# XXX youth_voting is ICPSR dataset #35012
# which we do not have permission to distribute
# unfortunately the bug doesn't show up on the other datasets we do have
use tests/youth_voting

//There is a distinct difference that cutting out the missing data makes:
count
//->  4,483

count if !missing(HSMINORITY) & !missing(HSMAJORITY) & !missing(INFORMED_VOTING) & !missing(HSDIVERSE)
//->  2,768

// So therefore these two should be training on very different slices
// in fact, they are, *but the difference is not as much as it should be* which is even weirder. hmmmmm.
cv Y1 svm HSMINORITY HSMAJORITY INFORMED_VOTING HSDIVERSE, est(c(1)  gamma(1))
cv Y2 svm HSMINORITY HSMAJORITY INFORMED_VOTING HSDIVERSE if !missing(HSMINORITY) & !missing(HSMAJORITY) & !missing(INFORMED_VOTING) & !missing(HSDIVERSE), est(c(1)  gamma(1))


