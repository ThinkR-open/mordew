case_passes <- function(
  answers,
  calls
) {
  if (length(answers) == 0) {
    return(
      length(
        calls
      ) ==
        0
    )
  }
  any(
    vapply(
      answers,
      answer_given,
      logical(
        1
      ),
      calls = calls
    )
  )
}

answer_given <- function(
  answer,
  calls
) {
  all(
    vapply(
      answer,
      call_made,
      logical(
        1
      ),
      calls = calls
    )
  )
}

call_made <- function(
  expected,
  calls
) {
  any(
    vapply(
      calls,
      call_matches,
      logical(
        1
      ),
      expected = expected
    )
  )
}
