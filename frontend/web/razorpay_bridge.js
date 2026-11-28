window.openRazorpayCheckout = function(options) {
  return new Promise(function(resolve) {
    if (typeof Razorpay === 'undefined') {
      resolve({ status: 'error', message: 'Razorpay checkout script not loaded' });
      return;
    }

    var settled = false;
    var lastError = null;

    var opts = Object.assign({}, options || {});

    opts.handler = function(response) {
      if (settled) return;
      settled = true;
      resolve({
        status: 'success',
        orderId: response.razorpay_order_id,
        paymentId: response.razorpay_payment_id,
        signature: response.razorpay_signature
      });
    };

    var userOnDismiss = (opts.modal && opts.modal.ondismiss) ? opts.modal.ondismiss : null;
    opts.modal = opts.modal || {};
    opts.modal.ondismiss = function() {
      if (userOnDismiss) {
        try { userOnDismiss(); } catch (e) {}
      }
      if (settled) return;
      settled = true;
      resolve({
        status: 'dismissed',
        lastError: lastError
      });
    };

    try {
      var rzp = new Razorpay(opts);

      rzp.on('payment.failed', function(response) {
        if (response && response.error) {
          lastError = response.error.description || response.error.reason || 'Payment failed';
        }
      });

      rzp.open();
    } catch (err) {
      if (!settled) {
        settled = true;
        resolve({
          status: 'error',
          message: err && err.message ? err.message : String(err)
        });
      }
    }
  });
};
