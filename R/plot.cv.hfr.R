#' @name plot.cv.hfr
#' @title Plot the dendrogram of an HFR model
#' @description Plots the dendrogram of a fitted \code{cv.hfr} model. The heights of the
#' levels in the dendrogram are given by a shrinkage vector, with a maximum (unregularized)
#' overall graph height of \eqn{p}{p} (the number of covariates in the regression).
#' Stronger shrinkage leads to a shallower hierarchy.
#'
#' @details The dendrogram is generated using hierarchical clustering and modified
#' so that the height differential between any two splits is the shrinkage weight of
#' the lower split (ranging between \code{0} and \code{1}). With no shrinkage, all shrinkage weights
#' are equal to \code{1} and the dendrogram has a height of \eqn{p}{p}. With shrinkage
#' the dendrogram has a height of \eqn{(\kappa \times p)}{(\code{kappa} x p)}.
#'
#' The leaf nodes are colored to indicate the coefficient sign, with the size indicating
#' the absolute magnitude of the coefficients.
#'
#' A color bar on the right indicates the relative contribution of each level to the
#' coefficient of determination, with darker hues representing a larger contribution.
#'
#' @param x Fitted 'cv.hfr' model.
#' @param kappa The hyperparameter used for plotting. If empty, the optimal value is used.
#' @param show_details print model details on the plot.
#' @param max_leaf_size maximum size of the leaf nodes. Default is \code{max_leaf_size=3}.
#' @param ... additional methods passed to \code{plot}.
#' @return A plotted dendrogram.
#' @author Johann Pfitzinger
#'
#' @examples
#' x = matrix(rnorm(100 * 20), 100, 20)
#' y = rnorm(100)
#' fit = cv.hfr(x, y, kappa = seq(0, 1, by = 0.1))
#' plot(fit, kappa = 0.5)
#'
#' @export
#'
#' @seealso \code{\link{cv.hfr}}, \code{\link{predict}} and \code{\link{coef}} methods

plot.cv.hfr <- function(
  x,
  kappa = NULL,
  show_details = TRUE,
  max_leaf_size = 3,
  ...
) {

  if (!inherits(x, 'cv.hfr'))
    stop("object must be of class 'cv.hfr'")
  if (is.null(kappa) && is.null(x$best_kappa))
    stop("must provide 'kappa'")
  if (is.null(kappa) && !is.null(x$best_kappa)) {
    kappa <- x$best_kappa
  }
  if (!is.null(kappa)) {
    if (is.null(x$kappa))
      stop("no 'kappa' in 'object'")
    if (!any(round(kappa, 6)==round(x$kappa, 6)))
      stop("'kappa' must be in 'kappa' of the object")
    return_ix <- which(round(kappa, 6)==round(x$kappa, 6))
  }
  if (kappa == 0)
    stop("'kappa' must be larger than 0 to plot")
  if (any(is.na(x$coefficients)))
    warning("removing variables with 'NA' coefficients")

  clust <- x$hgraph$cluster_object
  phi <- x$hgraph$shrinkage_vector[, return_ix]
  included_levels <- x$hgraph$included_levels
  coefs <- x$coefficients[, return_ix]
  coefs <- coefs[!is.na(coefs)]
  explained_var <- x$hgraph$explained_variance[, return_ix]
  if (x$intercept) {
    coefs <- coefs[-1]
    phi <- phi[-length(phi)]
    explained_var <- explained_var[-1]
  }

  aggr <- diag(length(phi))
  aggr[lower.tri(aggr)] <- 1
  theta <- rev(as.numeric(aggr %*% phi))

  dof <- rev(sapply(x$hgraph$full_level_output$S, nrow))
  dof <- c(dof[1], dof[-1] - dof[-length(dof)])

  heights <- rep(0, length(included_levels))
  heights[rev(included_levels)] <- theta * dof

  var_names <- names(coefs)

  plot_expl_var_bar <- rep(NA, length(included_levels))
  plot_expl_var_bar[included_levels] <- explained_var
  for (i in length(plot_expl_var_bar):1) {
    if (is.na(plot_expl_var_bar[i])) {
      if (i==length(plot_expl_var_bar)) {
        plot_expl_var_bar[i] <- 0
      } else {
        plot_expl_var_bar[i] <- plot_expl_var_bar[i+1]
      }
    }
  }

  .draw_dendro(clust, coefs, heights, plot_expl_var_bar, var_names, x$df[return_ix], show_details, max_leaf_size)

}
