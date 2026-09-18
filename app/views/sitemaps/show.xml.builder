xml.instruct!
xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
  xml.url do
    xml.loc root_url
  end

  xml.url do
    xml.loc genres_url
    xml.changefreq "daily"
  end

  xml.url do
    xml.loc plans_url
  end

  xml.url do
    xml.loc blog_url
    xml.changefreq "weekly"
  end

  @genres.each do |genre|
    xml.url do
      xml.loc genre_url(genre)
      xml.lastmod genre.updated_at.to_date.iso8601
      xml.changefreq "weekly"
    end
  end

  @tracks.each do |track|
    xml.url do
      xml.loc track_url(track)
      xml.lastmod track.published_at.to_date.iso8601 if track.published_at
    end
  end

  @posts.each do |post|
    xml.url do
      xml.loc blog_post_url(post)
      xml.lastmod post.published_at.to_date.iso8601
    end
  end

  @pages.each do |page|
    xml.url do
      xml.loc "#{root_url.chomp('/')}/#{page.slug}"
      xml.lastmod page.updated_at.to_date.iso8601
    end
  end
end
