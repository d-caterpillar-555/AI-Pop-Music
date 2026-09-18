module Subscriptions
  # Grants access to one genre, respecting the plan's limit.
  #
  # The row lock is the point: two tabs adding the last genre slot at the same
  # moment must not both succeed. A read-then-write without the lock would pass
  # both checks before either committed and hand out one slot twice.
  class AddGenre
    def self.call(...) = new(...).call

    def initialize(subscription:, genre:)
      @subscription = subscription
      @genre = genre
    end

    def call
      entitlement = nil
      failure = nil

      subscription.with_lock do
        if subscription.entitled?(genre)
          failure = :already_entitled
        elsif subscription.at_genre_limit?
          failure = :genre_limit_reached
        else
          entitlement = subscription.genre_entitlements.create!(genre: genre)
        end
      end

      failure ? Result.failure(failure) : Result.success(entitlement)
    rescue ActiveRecord::RecordNotUnique
      # Lost a race against a concurrent insert of the same genre.
      Result.failure(:already_entitled)
    end

    private

    attr_reader :subscription, :genre
  end
end
