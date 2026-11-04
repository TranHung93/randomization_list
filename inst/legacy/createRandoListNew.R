#' Quickly create composite strata based on vectors of strata
#' @description Combines vectors of strata into one vector of composite strata
#' @param ... named vectors of strata, must follow the convention of "actual/friendly name" = "stratum code"
#' For example: c(HTD="001", NHTD="010")
#' @param compartments Behaves the same as ..., but uses a list of vectors of strata
#' @param code_sep A character string to separate the stratum codes. Default to '-'. Will be ignored if have code_pattern.
#' @param code_pattern Pattern of the composite strata code, following the glue convention. Each vector of strata is represented by a number starting from 1, in the same order as specified in \code{param}. For example "{1}-{2}".
#' @return a named vector of composite strata. Names
#' @details Last changed April 2021 - TD
#' @export
composite_strata <- CS <- function(..., compartments = list(), code_sep = "-", code_pattern = NULL, name_sep = "."){
  # browser()
  compartment_strata <- append(list(...), compartments)
  stopifnot(length(compartment_strata) > 1)
  # get the matrix of names and codes by expand.grid. Then using apply to row-wisely concatenate them via `paste`
  composite_stratum_names <- apply(expand.grid(lapply(compartment_strata, names)), 1,
                                   function(x) paste(x, collapse = name_sep))
  if (!length(code_pattern))
    return(structure(apply(expand.grid(compartment_strata), 1,
                            function(x) paste(x, collapse = code_sep)),
           names = composite_stratum_names))
  # This function replaces glue::glue in the case code_pattern is used
  # Using code_pattern is more flexible as it allows sophisticated things .
  # like switch places of stratum code
  # while still maintaining name orders.
  get_vars <- function(pt){
    #Get the indices of opening and closing brackets
    open_match.index <- gregexpr("{", pt, perl=TRUE)[[1]]
    close_match.index <- gregexpr("}", pt, perl=TRUE)[[1]]
    #They must be 1:1; otherwise, the pattern is ill-formed.
    if (length(open_match.index) != length(close_match.index)) stop("Ill-formed pattern!")
    #Pair the brackets together
    #And get the starting and ending indices of what are inside
    #i.e. the variable names
    match_idxes <- lapply(seq_along(open_match.index),
                          function(i){
                            o.idx <- open_match.index[i] + 1
                            c.idx <- close_match.index[i] - 1
                            if (o.idx > c.idx) stop("Ill-formed pattern!", call=FALSE)
                            o.idx:c.idx
                          })
    #Expose the variable names
    vars <- lapply(match_idxes, function(idx) strsplit(pt, NULL)[[1]][idx])
    #Collect the rest
    non.vars <- paste0(strsplit(pt, NULL)[[1]][-unlist(match_idxes)], collapse = "")

    list(
      vars = sapply(vars, paste0, collapse=""),
      non.vars = strsplit(non.vars, "{}", perl=TRUE)[[1]]
    )
  }
  x <- get_vars(code_pattern)
  # browser()
  if (length(x$vars) != length(compartment_strata)) stop("Ill-formed pattern!")
  if (any(is.na(as.numeric(x$vars)))) stop("Ill-formed pattern!")

  composite_grid <- expand.grid(compartment_strata)
  composite_grid <- as.data.frame(composite_grid)
  colnames(composite_grid) <- seq_len(ncol(composite_grid))

  vars <- x$vars
  non.vars <- x$non.vars
  for (v in vars) if (!v %in% names(composite_grid)) stop("Ill-formed pattern!")
  stratum_text <- character(nrow(composite_grid))
  for (i in seq_along(non.vars)){
    stratum_text <- paste0(stratum_text, non.vars[i])
    if (i <= length(vars)){
      stratum_text <- paste0(stratum_text, composite_grid[[vars[i]]])
    }
  }

  names(stratum_text) <- composite_stratum_names
  stratum_text

}

#'  Create a simple randomization list for a strata (block randomization)
#'  @description This function create a simple randomization list for a strata (block randomization)
#'  @param nPat Total number of patients within each stratum.
#'   - If length of \code{nPat} == 1, assuming that is the number of patients in every stratum.
#'   - If length of \code{nPat} == length(strata), the number of patients in each stratum.
#'   - Otherwise throw an error.
#'  @param arms The number of arms/patient groups. Default is 2.
#'  @param arm_names a vector of length \code{arms}. Names of arms, e.g. "Control", "Intervention"
#'  @param strata A named vector of strata. The names will be the actual names of the strata, while the values will be the ids added as prefixes to the randomisation IDs.
#'  @param blocklength length of the block, if > 1 blocks then they will be sample using \code{blocklength_prob}.
#'  The default for a 2-arm trial is variable blocklengths of 4 and 6 (must be a multiple of "arms"!)
#'  @param blocklength_prob Probability of each blocklength, default will be 1/(number of block lengths) i.e. uniformly sampled
#'  @param first_patid Patient id of first patient
#'  @param patid_format control parameters passed to \code{formatC} to prettify Patient IDs. If NULL, they will be kept as-is (which is NOT recommended)
#'  @param n.block_permute Perform permutation of patient IDs within every subsequent N blocks. Should be a non-negative integer.
#'   Default to 0 (no permutation), i.e. patids are incrementally ordered.
#'   If set to something very large (e.g \code{Inf}) then a single permutation of all patient IDs will be performed.
#'  @param RanNo_pattern Pattern of the composite strata code, following the glue convention.
#'  It combines the values of variable names taken from the resulting data.frame, i.e: \code(stratum, statum_names, pat_id (!not pat_id.stratum), block_number, arm). Defaults to "{stratum}-{pat_id}".
#'  @return A data.frame with randomisation list. If the number of strata is >1, it is a list with each component such a data.frame
#'  @author Marcel Wolbers, Trinh Dong Huu Khanh, and the OUCRU Biostatistics Group
#'  @details Last changed 01st June 2024 - TD, Changelog: add code to restore RNGkind to 3.6, as requested by RG, contact TD for details
#'  @export
createRandoList <- function(nPat,
                            arms = 2,
                            arm_names = LETTERS[seq_len(arms)],
                            strata = c(HTD = "001"),
                            blocklength = arms*(2:3),
                            blocklength_prob = rep(1/length(blocklength), length(blocklength)),
                            first_patid = 1,
                            patid_format = list(flag="0", width=nchar(max(nPat + first_patid - 1))),
                            n.block_permute = 0,
                            RanNo_pattern = "{stratum}-{pat_id}"){
  # browser()
  stopifnot(sum(nPat) > arms & sum(nPat) > 0); stopifnot(length(nPat) == 1||length(nPat) == length(strata))
  if (any(blocklength%%arms>0)) stop("Block lengths and number of arms not compatible!")

  #check if R>3.6; choose the legacy sampler

  with(version, {
    if ((as.integer(major) >= 4) || (as.integer(major) == 3 && as.numeric(minor) >= 6.0)){
      if (RNGkind()[3] != "Rounding" && identical(parent.frame(4), globalenv()))
        message("RNG changed to rounding with this version of R")
      suppressWarnings(RNGkind(sample.kind = "Rounding"))
    }
  })

  r.arm <-  NULL # the randomized arm for each patient
  blocknumber <- NULL
  b.num <- 1

  if (length(strata) > 1){
    if (length(nPat) == 1) nPat <- rep(nPat, length(strata))
    enum <- function(x) structure(seq_along(x), names=names(x))
  return(
      sapply(enum(strata),
             function(i) {
                dt <- createRandoList(nPat[[i]], arms, arm_names,
                                strata = strata[i],
                                blocklength, blocklength_prob,
                                first_patid, patid_format,
                                n.block_permute, RanNo_pattern)
                names(dt)[1] <- "pat_id.stratum"
                dt
             }, simplify = FALSE, USE.NAMES = TRUE)
    )
  }

  if (!nPat) return(NULL)

  while (length(r.arm)<nPat){
    # determine current blocklength (randomly select if more than one blocklength was provided)
    currBlocklength <- ifelse(length(blocklength)>1,
                              sample(blocklength,size=1,prob=blocklength_prob),
                              blocklength)
    # determine randomized arms for current block
    r.block <- rep(NA,currBlocklength)
    r.blockorder <- sample(1:currBlocklength,currBlocklength) #random order of block elements
    for (j in 1:arms){
      elelements.armj <- r.blockorder[(1+(j-1)*currBlocklength/arms):(j*currBlocklength/arms)]
      r.block[elelements.armj] <- ifelse(is.null(arm_names),paste("Arm",j,sep=""),arm_names[j])
    }
    r.arm <- c(r.arm,r.block)
    blocknumber <- c(blocknumber,rep(b.num,currBlocklength))
    b.num <- b.num+1
  }
  r.arm <- r.arm[1:nPat]
  blocknumber <- blocknumber[1:nPat]
  pat.id <- first_patid+(0:(nPat-1))

  #Perform block-wise pat.id permutation
  if (n.block_permute){
    # n.permut.block <- ((b.num-1) %/% n.block_permute) + as.logical((b.num-1) %% pemute_patid_every)
    permut.block.number <- sapply(blocknumber - 1, "%/%", n.block_permute) + 1

    pat.id <- unlist(sapply(sort(unique(permut.block.number)), function(curr.permut.block.number){
      curr.pat.id <- pat.id[permut.block.number == curr.permut.block.number]
      sample(curr.pat.id, replace = FALSE, size = length(curr.pat.id))
    }))
  }

  #nicer format for blocknumber and pat.id
  #OLD: blocknumber <- formatC(blocknumber,flag="0",width=max(nchar(blocknumber)))
  if (length(patid_format)){
    pat.id <- do.call(formatC, append(patid_format, list(pat.id), after = 0))
  }
  #OLD: pat.id <- formatC(pat.id,flag="0",width=nchar(max(pat.id)))

  # Create output data.frame
  dt <- data.frame(pat_id=pat.id,
             stratum_name = names(strata),
             stratum = unname(strata),
             block_number = blocknumber,
             arm=r.arm)
  if (n.block_permute) dt$permute.block <- permut.block.number
  if (length(RanNo_pattern)){
    # This function replaces glue::glue in the case code_pattern is used
    # Using code_pattern is more flexible as it allows sophisticated things .
    # like switch places of stratum code
    # while still maintaining name orders.
    # NOT TODO: support for escape brackets.
    get_vars <- function(pt){
      #Get the indices of opening and closing brackets
      open_match.index <- gregexpr("{", pt, perl=TRUE)[[1]]
      close_match.index <- gregexpr("}", pt, perl=TRUE)[[1]]
      #They must be 1:1; otherwise, the pattern is ill-formed.
      if (length(open_match.index) != length(close_match.index)) stop("Ill-formed RanNo pattern!")
      #Pair the brackets together
      #And get the starting and ending indices of what are inside
      #i.e. the variable names
      match_idxes <- lapply(seq_along(open_match.index),
                            function(i){
                              o.idx <- open_match.index[i] + 1
                              c.idx <- close_match.index[i] - 1
                              if (o.idx > c.idx) stop("Ill-formed RanNo pattern!")
                              o.idx:c.idx
                            })
      #Expose the variable names
      vars <- lapply(match_idxes, function(idx) strsplit(pt, NULL)[[1]][idx])
      #Collect the rest
      non.vars <- paste0(strsplit(pt, NULL)[[1]][-unlist(match_idxes)], collapse = "")

      list(
        vars = sapply(vars, paste0, collapse=""),
        non.vars = strsplit(non.vars, "{}", perl=TRUE)[[1]]
      )
    }

    splitpt <- get_vars(RanNo_pattern)
    vars <- splitpt$vars
    non.vars <- splitpt$non.vars

    for (v in vars) if (!v %in% names(dt)) stop(paste(v), " not found in randomisation data!")
    ranno_text <- character(nPat)
    for (i in seq_along(non.vars)){
      ranno_text <- paste0(ranno_text, non.vars[i])
      if (i <= length(vars)){
         ranno_text <- paste0(ranno_text, dt[[vars[i]]])
      }
    }
    dt$RanNo <- ranno_text
  }
  #Restore RNGkind
  with(version, {
    if ((as.integer(major) >= 4) || (as.integer(major) == 3 && as.numeric(minor) >= 6.0))
      RNGkind(sample.kind = "default")
  })

  dt
}
