module Subscriptions
  class RemoveGenre
    def self.call(...) = new(...).call

    def initialize(subscription:, genre:)
      @subscription = subscription
      @genre = genre
    end

    def call
      removed = false

      subscription.with_lock do
        entitlement = subscription.genre_entitlements.find_by(genre_id: genre.id)

        if entitlement
          entitlement.destroy!
          removed = true
          subscription.record_event!("genre_removed", { genre_id: genre.id, genre_slug: genre.slug })
        end
      end

      removed ? Result.success : Result.failure(:not_entitled)
    end

    private

    attr_reader :subscription, :genre
  end
end
