# Catalogue search.
#
# Postgres full-text search over track and genre titles, not Meilisearch. The
# catalogue in v1 is small enough that a database query is faster to run and
# faster to reason about, and it cannot go stale. Meilisearch earns its place
# when typo tolerance and faceting on a large catalogue matter, which is a
# later problem with a known migration path.
class CatalogSearch
  Result = Data.define(:kind, :record)

  def self.call(query, limit: 25)
    new(query, limit: limit).call
  end

  def initialize(query, limit: 25)
    @query = query
    @limit = limit
  end

  def call
    genre_matches + track_matches
  end

  private

  attr_reader :query, :limit

  def pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"

  def genre_matches
    Genre.published
      .where("name ILIKE :q OR description ILIKE :q", q: pattern)
      .ordered
      .limit(5)
      .map { |genre| Result.new(kind: :genre, record: genre) }
  end

  def track_matches
    Track.published
      .where("title ILIKE :q OR mood ILIKE :q OR artist_name ILIKE :q", q: pattern)
      .ordered
      .limit(limit)
      .map { |track| Result.new(kind: :track, record: track) }
  end
end
