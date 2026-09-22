#' Plot Graph-Based Simulated Event History Data
#'
#' Visualizes [sim_event_graph()] output by plotting individual event times
#' colored and shaped by event type. Each individual's timeline is displayed
#' horizontally with events marked along it.
#'
#' Colors and shapes can be customized by adding
#' `+ ggplot2::scale_color_manual(...)`/`+ ggplot2::scale_shape_manual(...)`
#' to the returned plot.
#'
#' @param data A `data.table` as returned by [sim_event_graph()], containing
#'   at least the columns `id`, `time`, and `delta`.
#' @param title Character string specifying the plot title. Defaults to
#'   `"Event Data"`.
#'
#' @return A `ggplot` object representing the event data visualization.
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
#'   ggplot2::scale_color_manual(values = c(start = "grey", `0` = "blue", `1` = "red"))
#' @export
plot_event_data <- function(data, title = "Event Data") {
  time <- id <- delta <- NULL

  data <- data.table::copy(data.table::as.data.table(data))[,
    c("id", "time", "delta")
  ]

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
      delta = rep("start", n)
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
        shape = factor(delta),
        color = factor(delta)
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
