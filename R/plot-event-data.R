#' Plot Graph-Based Simulated Event History Data
#'
#' One horizontal timeline per individual, with events marked by type.
#'
#' @param data Output of [sim_event_graph()].
#' @param title Character. Plot title. Default `"Event Data"`.
#'
#' @return A `ggplot` object.
#' @seealso [sim_event_graph()]
#' @examples
#' graph <- sim_graph(
#'   censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1)
#' )
#' data <- sim_event_graph(graph, n = 10)
#' plot_event_data(data)
#'
#' # Custom colors:
#' plot_event_data(data) +
#'   ggplot2::scale_color_manual(
#'     values = c(start = "grey", censoring = "blue", death = "red")
#'   )
#' @export
plot_event_data <- function(data, title = "Event Data") {
  time <- id <- event <- max_time <- NULL

  data <- data.table::copy(data.table::as.data.table(data))[,
    c("id", "time", "event")
  ]
  data[, event := as.character(event)]

  # Extract unique patient IDs and number of patients
  n <- length(unique(data$id))

  # We order according to time
  ordering <- data[, list(max_time = max(time)), by = id]
  data.table::setkey(ordering, max_time)

  # We add the start time to the data set
  data[, id := factor(id, levels = ordering$id)]
  plotdata <- rbind(
    data,
    data.table::data.table(
      id = unique(data$id),
      time = rep(0, n),
      event = rep("start", n)
    )
  )

  ggplot2::ggplot(plotdata) +
    ggplot2::geom_line(
      ggplot2::aes(x = time, y = id, group = id),
      color = "grey60",
      linewidth = 0.7
    ) +
    ggplot2::geom_point(
      ggplot2::aes(
        x = time,
        y = id,
        shape = event,
        color = event
      ),
      size = 2.5,
      data = data,
      alpha = 0.8
    ) +
    ggplot2::theme_minimal(base_size = 15) +
    ggplot2::labs(
      title = title,
      x = "Time",
      y = "Patient ID",
      shape = "Event Type",
      color = "Event Type"
    ) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = 10)),
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = 10)),
      axis.text.y = ggplot2::element_blank(),
      legend.position = "top"
    )
}
