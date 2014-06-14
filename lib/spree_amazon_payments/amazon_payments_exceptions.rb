module SpreeAmazonPayments
  class InvalidPaymentMethodException < RuntimeError; end
  class AmazonRejectedAuthorizationException < RuntimeError; end
  class ProcessingFailureException < RuntimeError; end
  class TransactionTimedOutException < RuntimeError; end
  class AmazonRejectedCaptureException < RuntimeError; end
  class AmazonRejectedRefundException < RuntimeError; end
end