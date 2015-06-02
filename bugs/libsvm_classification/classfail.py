#!/bin/env python3
# libsvm has a behaviour which I have only seen on the attached dataset
# The data has a 4-level categorical outcome, and 1.5k boolean predictors (almost all false)
# and a heavy bias towards the last category
# 
# When we run libsvm's svm_predict_probability(), a reasonable distribution of categories comes out
# when we run svm_predict(), *all categories are forced to the dominant category*
# Is this expected or a dangerously subtle glitch that no one yet noticed?

# --- util ----
def tab(s):
    """
    like 'tab Y' in Stata
    XXX -> is there a better way to do this?
    why is there pandas.crosstab() but not pandas.tabulate()?
    """
    return pandas.Series(s).groupby(by = lambda x: s[x]).count()

# --- script ---
import pandas
import sklearn.svm

def correct(X,Y,labels):
    G = sklearn.svm.SVC(probability=True)
    G.fit(X, Y)
    Pp = G.predict_proba(X) #a matrix as tall as the dataset as as wide as the number of categories
    Pp = Pp.argmax(axis=1)  #pick a prediction by choosing the largest probability for each datapoint;
                            # this does 'arg'max so it gets the *index into the libsvm category labels*, 
    P = [G.classes_[i] for i in Pp] #known in C as svm_model->labels[] and in python as G.classes_[]),
                            # not necessarily the actual inputted labels
    P = [labels[e] for e in P]
    
    P = pandas.Series(P)
    return P


def incorrect(X,Y,labels):
    G = sklearn.svm.SVC()
    G.fit(X, Y)
    P = G.predict(X)
    P = [labels[e] for e in P]
    P = pandas.Series(P)
    return P


if __name__ == '__main__':
    import sys
    
    D = pandas.read_csv(sys.argv[1] if len(sys.argv)>1 else "classification_bug.csv")
    D["category"], category_labels = D["category"].factorize() #sklearn isn't smart enough to do this for us, of course. and pandas isn't smart enough to keep the value labels attached to the new Series. 
    # split into the form sklearn needs
    Y, X = D.ix[:, 0], D.ix[:, 1:]

    
    print("Training:"); print(tab(Y)); print()
    print("Incorrect predictions:"); print(tab(incorrect(X,Y,category_labels))); print()
    print("Correct predictions:"); print(tab(correct(X,Y,category_labels))); print()
    

