# A tiny explicit result for services whose failures are expected outcomes
# rather than exceptions. Reaching a genre limit is normal operation, not an
# error to log or a 500 to render.
class Result
  attr_reader :value, :error

  def self.success(value = nil)
    new(success: true, value: value, error: nil)
  end

  def self.failure(error, value: nil)
    new(success: false, value: value, error: error)
  end

  def initialize(success:, value:, error:)
    @success = success
    @value = value
    @error = error
  end

  def success? = @success
  def failure? = !@success
end
