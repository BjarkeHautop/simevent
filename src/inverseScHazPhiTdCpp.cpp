#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
double inverseScHazPhiTdCpp(
  double p,
  double t,
  NumericVector T_star,
  double lower,
  double upper,
  NumericVector eta,
  NumericVector nu,
  NumericVector beta2,
  NumericVector phi0,
  NumericVector at_risk,
  double tol = 1e-9,
  int max_iter = 100
) {

  int K = eta.size();

  // Precompute everything that is invariant to u (the bisection variable):
  // ra = rate * t and its gamma cdf G_a never involve u, only rb = rate * (t + u) does.
  std::vector<double> shape(K), rate(K), const_part(K), G_a(K), pow_t(K);
  std::vector<bool> active(K), near_zero(K);

  for (int k = 0; k < K; ++k) {
    active[k] = at_risk[k] != 0;
    if (!active[k]) continue;

    shape[k] = nu[k];
    rate[k]  = beta2[k];
    near_zero[k] = std::abs(rate[k]) < 1e-12;

    const_part[k] = eta[k] * shape[k] * phi0[k] * std::exp(rate[k] * T_star[k]);

    if (near_zero[k]) {
      // Standard Weibull cumulative hazard if beta_2 = 0
      pow_t[k] = std::pow(t, shape[k]);
    } else {
      double ra = rate[k] * t;
      G_a[k] = R::pgamma(ra, shape[k], 1.0, 1, 0);
    }
  }

  // Closed-form cumulative hazard; only the u-dependent piece is recomputed per call
  auto cum_haz = [&](double u) {
    double total = 0.0;

    for (int k = 0; k < K; ++k) {
      if (!active[k]) continue;

      double integral;

      if (near_zero[k]) {
        integral = (std::pow(t + u, shape[k]) - pow_t[k]) / shape[k];
      } else {
        double rb = rate[k] * (t + u);
        double G_b = R::pgamma(rb, shape[k], 1.0, 1, 0);

        integral =
          std::pow(rate[k], -shape[k]) *
          R::gammafn(shape[k]) *
          (G_b - G_a[k]);
      }

      total += at_risk[k] * const_part[k] * integral;
    }

    return total;
  };

  // Root finding via bisection
  double a = lower;
  double b = upper;

  double fa = cum_haz(a) - p;
  double fb = cum_haz(b) - p;

  if (fa * fb > 0) {

    Rcout << "cum_haz(a) = " << cum_haz(a)
          << ", cum_haz(b) = " << cum_haz(b)
          << ", p = " << p
          << std::endl;

    stop("Root not bracketed");
  }

  for (int iter = 0; iter < max_iter; ++iter) {

    double mid = 0.5 * (a + b);
    double fmid = cum_haz(mid) - p;

    if (std::abs(fmid) < tol)
      return mid;

    if (fa * fmid < 0) {
      b = mid;
      fb = fmid;
    } else {
      a = mid;
      fa = fmid;
    }
  }

  warning("Maximum iterations reached");

  return 0.5 * (a + b);
}
