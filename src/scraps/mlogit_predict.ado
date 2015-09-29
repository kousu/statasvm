/* mlogit_predict: extract classifications from an mlogit model
 * mlogit only gives probabilities. actually translating this to classes is hard.
 *
 */

program define mlogit_predict
  if("`e(cmd)'"!="mlogit") {
    di as error "mlogit_predict must only be run after mlogit"
    exit 1
  }
  
  gettoken target 0 : 0
  confirm new var `target'
  
  qui clone `target' `e(depvar)' if 0
  local L : variable label `target'
  if("`L'"!="") {
    label variable `target' "Predicted `L'"
  }
  
  // this is the standard max-finding algorithm
  // written sideways so that it can use Stata's vectorizations
  // try not to get lost
  tempvar max_p
  tempvar cur_p
  
  qui gen `max_p' = 0
  
  levelsof `e(depvar)', local(levels)
  foreach c of local levels {
     
     qui predict `cur_p', outcome(`c')
     replace `target' = `c' if `cur_p' > `max_p'
     replace `max_p' = `cur_p' if `cur_p' > `max_p'
     
     qui drop `cur_p'
  }
end
