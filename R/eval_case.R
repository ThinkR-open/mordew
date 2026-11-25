#' Describe an eval case
#'
#' Describes a question to ask the model and the answers to accept.
#'
#' @param question Question to ask the model.
#' @param ... Answers to accept, each a [tool_call()], or a list of
#'   [tool_call()] when the answer takes several calls. With no answer, the
#'   model must call no tool.
#'
#' @return A list with elements `question` and `answers`.
#'
#' @export
eval_case <- function(
  question,
  ...
) {
  list(
    question = question,
    answers = lapply(
      list(
        ...
      ),
      function(answer) {
        if (is.null(answer$tool)) {
          return(
            answer
          )
        }
        list(
          answer
        )
      }
    )
  )
}
