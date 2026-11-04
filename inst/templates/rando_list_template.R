# =============================================================================
# Randomisation list for study <STUDY>                     (SOP PR-BST-DM-001)
# Written by: <statistician>, <MonthYear>    Approved by: <Head of Biostatistics>
#
# STATISTICIAN: run with DUMMY <- TRUE (dummy list in the Biostatistics folder).
# PHARMACIST:   change ONLY the lines marked "PHARMACIST", then run in a clean
#               session:   Rscript --vanilla <this file>
# =============================================================================

library(randolist)   # version used: see packageVersion("randolist") in the log

# ---- Status and seed --------------------------------------------------------
DUMMY      <- TRUE                     # PHARMACIST: set to FALSE
DUMMY_SEED <- 20261104                 # do not change
SEED       <- DUMMY_SEED               # PHARMACIST: replace with generate_seed()
out_dir    <- "V:/BIOSTATISTICS/Dummy_Randomizationlists/<STUDY>_<MonYYYY>"
                                       # PHARMACIST: secure Pharmacy folder

check_final_setup(dummy = DUMMY, seed = SEED, dummy_seed = DUMMY_SEED)

# ---- Design (from the protocol) --------------------------------------------
study     <- "<STUDY>"
arm_names <- dummy_arm_names(c("<Trt>", "<Ctl>"), dummy = DUMMY)
strata    <- c(All = "001")            # or composite_strata(...)
n_max     <- 100                       # maximum anticipated size per stratum

rl <- createRandoList(
  nPat             = 2 * n_max,        # SOP: at least 100% longer
  arms             = 2,
  arm_names        = arm_names,
  strata           = strata,
  blocklength      = c(4, 6),          # 3 arms: c(6, 9)
  blocklength_prob = c(0.75, 0.25),
  seed             = SEED
)

# ---- Verify and write -------------------------------------------------------
chk <- check_rando_list(rl)
print(chk)
stopifnot(chk$ok)

write_rando_list(rl, dir = out_dir, study = study, dummy = DUMMY)
