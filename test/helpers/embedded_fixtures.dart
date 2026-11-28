// In-memory copies of `test/fixtures/` for `integration_test` on a device,
// where the host filesystem is unavailable. Verified against disk by
// `test/helpers/fixture_reader_test.dart`.
// ignore_for_file: lines_longer_than_80_chars

const Map<String, String> embeddedTextFixtures = {
  'tmdb/authentication.json':
      r'''{ "success": true, "status_code": 1, "status_message": "Success." }
''',
  'tmdb/collection.json': r'''{
  "id": 0,
  "name": "Collection",
  "overview": "Overview of the collection.",
  "poster_path": "/collection.jpg",
  "parts": [
    {
      "id": 0,
      "title": "Part",
      "original_title": "Part",
      "media_type": "movie",
      "overview": "Overview of the part.",
      "poster_path": "/part.jpg",
      "release_date": "2020-01-01",
      "genre_ids": [28],
      "vote_average": 7.0,
      "vote_count": 500
    }
  ]
}
''',
  'tmdb/credits.json': r'''{
  "cast": [
    { "id": 1, "name": "Actor 1", "character": "Role 1", "order": 0, "profile_path": "/a1.jpg" },
    { "id": 4, "name": "Actor 2", "character": "Role 2", "order": 1, "profile_path": null }
  ],
  "crew": [
    { "id": 2, "name": "Director 1", "job": "Director", "department": "Directing", "profile_path": null }
  ]
}
''',
  'tmdb/media_page.json': r'''{
  "page": 1,
  "results": [
    {
      "adult": false,
      "backdrop_path": "/b1.jpg",
      "genre_ids": [28, 12],
      "id": 101,
      "original_language": "en",
      "original_title": "Discover Movie 1",
      "overview": "First result.",
      "popularity": 90.0,
      "poster_path": "/d1.jpg",
      "release_date": "2021-03-01",
      "title": "Discover Movie 1",
      "vote_average": 7.9,
      "vote_count": 4200
    },
    {
      "adult": false,
      "backdrop_path": "/b2.jpg",
      "genre_ids": [35],
      "id": 102,
      "original_language": "fr",
      "original_title": "Discover Movie 2",
      "overview": "Second result.",
      "popularity": 80.0,
      "poster_path": "/d2.jpg",
      "release_date": "2019-07-12",
      "title": "Discover Movie 2",
      "vote_average": 7.1,
      "vote_count": 1300
    },
    {
      "adult": false,
      "backdrop_path": "/b3.jpg",
      "genre_ids": [18],
      "id": 103,
      "original_language": "en",
      "original_title": "Discover Movie 3",
      "overview": "Third result.",
      "popularity": 70.0,
      "poster_path": "/d3.jpg",
      "release_date": "2018-10-20",
      "title": "Discover Movie 3",
      "vote_average": 6.8,
      "vote_count": 900
    }
  ],
  "total_pages": 3,
  "total_results": 9
}
''',
  'tmdb/movie.json': r'''{
  "adult": false,
  "backdrop_path": "/backdrop.jpg",
  "belongs_to_collection": null,
  "genres": [
    { "id": 28, "name": "Action" },
    { "id": 878, "name": "Science Fiction" }
  ],
  "id": 0,
  "imdb_id": "tt0000000",
  "origin_country": ["US"],
  "original_language": "en",
  "original_title": "Movie",
  "overview": "Overview of the movie.",
  "popularity": 50.5,
  "poster_path": "/poster.jpg",
  "production_countries": [{ "iso_3166_1": "US", "name": "United States of America" }],
  "release_date": "2020-01-01",
  "runtime": 110,
  "status": "Released",
  "tagline": "A tagline.",
  "title": "Movie",
  "video": false,
  "vote_average": 7.5,
  "vote_count": 1000
}
''',
  'tmdb/person.json': r'''{
  "biography": "Biography of the person.",
  "birthday": "1970-01-01",
  "deathday": null,
  "gender": 2,
  "id": 0,
  "known_for_department": "Acting",
  "name": "Person",
  "place_of_birth": "Paris, France",
  "popularity": 30.0,
  "profile_path": "/person.jpg"
}
''',
  'tmdb/person_combined_credits.json': r'''{
  "cast": [
    {
      "id": 101,
      "media_type": "movie",
      "title": "Discover Movie 1",
      "character": "Role 1",
      "poster_path": "/d1.jpg",
      "release_date": "2021-03-01",
      "genre_ids": [28],
      "vote_average": 7.9,
      "vote_count": 4200
    }
  ],
  "crew": []
}
''',
  'tmdb/search_person.json': r'''{
  "page": 1,
  "results": [
    {
      "id": 1,
      "name": "Actor 1",
      "known_for_department": "Acting",
      "popularity": 30.0,
      "profile_path": "/a1.jpg",
      "known_for": []
    }
  ],
  "total_pages": 1,
  "total_results": 1
}
''',
  'tmdb/tv.json': r'''{
  "backdrop_path": "/backdrop.jpg",
  "created_by": [{ "id": 3, "name": "Creator 1", "profile_path": null }],
  "episode_run_time": [45],
  "first_air_date": "2020-01-01",
  "genres": [{ "id": 18, "name": "Drama" }],
  "id": 0,
  "in_production": false,
  "last_air_date": "2021-12-01",
  "last_episode_to_air": null,
  "name": "Show",
  "next_episode_to_air": null,
  "number_of_episodes": 0,
  "number_of_seasons": 0,
  "origin_country": ["US"],
  "original_language": "en",
  "original_name": "Show",
  "overview": "Overview of the show.",
  "popularity": 40.2,
  "poster_path": "/poster.jpg",
  "seasons": [],
  "status": "Ended",
  "type": "Scripted",
  "vote_average": 8.1,
  "vote_count": 800
}
''',
  'tmdb/tv_season.json': r'''{
  "_id": "season",
  "air_date": "2020-01-01",
  "id": 0,
  "name": "Season",
  "overview": "",
  "poster_path": "/season.jpg",
  "season_number": 0,
  "episodes": [
    {
      "air_date": "2020-01-01",
      "episode_number": 0,
      "id": 0,
      "name": "Episode",
      "overview": "Overview of the episode.",
      "runtime": 45,
      "season_number": 0,
      "still_path": "/still.jpg",
      "vote_average": 7.8
    }
  ]
}
''',
  'tmdb/videos.json': r'''{
  "results": [
    { "id": "v1", "iso_639_1": "en", "key": "abc123", "name": "Official Trailer", "site": "YouTube", "type": "Trailer", "official": true }
  ]
}
''',
  'tmdb/watch_providers.json': r'''{
  "results": {
    "FR": {
      "link": "https://www.themoviedb.org/movie/0/watch?locale=FR",
      "flatrate": [
        { "display_priority": 1, "logo_path": "/provider.jpg", "provider_id": 8, "provider_name": "Netflix" }
      ]
    },
    "US": {
      "link": "https://www.themoviedb.org/movie/0/watch?locale=US",
      "flatrate": [
        { "display_priority": 1, "logo_path": "/provider.jpg", "provider_id": 8, "provider_name": "Netflix" }
      ]
    }
  }
}
''',
  'trending_all_week.json': r'''{
  "page": 1,
  "results": [
    {
      "adult": false,
      "backdrop_path": "/a.jpg",
      "id": 1396,
      "name": "Breaking Bad",
      "original_name": "Breaking Bad",
      "overview": "A chemistry teacher turns to crime.",
      "poster_path": "/bb.jpg",
      "media_type": "tv",
      "original_language": "en",
      "genre_ids": [18, 80],
      "popularity": 410.2,
      "first_air_date": "2008-01-20",
      "vote_average": 8.9,
      "vote_count": 15000,
      "origin_country": ["US"]
    },
    {
      "adult": false,
      "backdrop_path": "/b.jpg",
      "id": 157336,
      "title": "Interstellar",
      "original_title": "Interstellar",
      "overview": "A team travels through a wormhole.",
      "poster_path": "/in.jpg",
      "media_type": "movie",
      "original_language": "en",
      "genre_ids": [12, 18, 878],
      "popularity": 380.1,
      "release_date": "2014-11-05",
      "video": false,
      "vote_average": 8.4,
      "vote_count": 36000
    },
    {
      "adult": false,
      "id": 6193,
      "name": "Leonardo DiCaprio",
      "original_name": "Leonardo DiCaprio",
      "media_type": "person",
      "popularity": 120.5,
      "gender": 2,
      "known_for_department": "Acting",
      "profile_path": "/ld.jpg"
    }
  ],
  "total_pages": 500,
  "total_results": 10000
}
''',
};

const Map<String, String> embeddedBinaryFixturesBase64 = {
  'export_v1.4.4.mdv':
      'UEsDBBQAAAgIAHuFeF1a7IYsOAAAADYAAAAIAAAAbWV0YS5jc3YrSy0qzszP00mtKMgvKklNcSzRKc4vLUpO5eUy1DEyMDLTNTTUNTIKMbC0MjCwMjDQMzAwiNIBAFBLAwQUAAAICAB7hXhd6OSBXsMAAAB7AQAACAAAAHNlZW4uY3N2jc7NSgNBEATgeyDvsA9Qm3SPGRNyE4LgQRGyJ2+T3SYZcX6Y6UQEH142iARPC03RdfkoDcPhaYB+ZYF6/RDkVFXKq9MTqkjcORVUcTXFl3M4SIFkX9Mgv62co/ogOEosUuczawkhXbzgecxm7MtsLS3e8xGGzKolbpk6Q1sab0FEbwCYCQ+9+hS/972X2Evz6K99GnrfEne82d5NRZkIesH+lD6b8V9mptuV6yu4vl3JYKwsdsUFN59NAEzH/wDzB/wAUEsDBBQAAAgIAHuFeF3EYhVKJQAAACYAAAAJAAAAbGlrZXMuY3N2K8lNSfJM0SmpLEjVKcksyUnl5TI1NdDJzS/LTNXxBZEKpqYGAFBLAwQUAAAICAB7hXhd6cFPNXcAAACMAAAAEQAAAG5vdGlmaWNhdGlvbnMuY3N2LccxCsJAEEbhXvAOHmAS/93S2sYmCFrZTcjErGycZWei5PaiCK/4ns9DfxrI1yLkybNQUXOpZ/aJqmRhkyO7kAmbPrtl7qWSlGQ6yP94ce3U07huNxEgf9Fl0vfu632JQPsod4qIaBAahCtw+NUCuFGgQCNnkw9QSwMEFAAACAgAe4V4XeFJ6lBgAAAAfgAAAAkAAABsaXN0cy5jc3ZdiTEKgDAQBHvBP/iALaKSR1hoY2Gt5sDDxAhZFH8v6cRmmGG8Jg5zEDC4pXPgcwqo9IIzJqXGoyzumevmNRHWNgjxUkGfWeU2ZTGJ7HI4WNv+dvvdtTHghXGLd5W9fgFQSwMEFAAACAgAe4V4XfPx9KN/AAAAmwAAAAwAAABxdWlja2FkZC5jc3Y9jMEKwjAQBe+C/+AHbOrbKBR6E7x4KYI9eUvJYiO2CclW8e+lIh5nBkZH35886TsJFXElTu089pJJUijRy4/CVCSr+IOSC/noVEiDPoRSLCr57HRYrxggfRLTjizs3qA2sB3XDdAAFYDrEmDABtx97T9chvjaLIdtYqC6p9sHUEsBAhQAFAAACAgAe4V4XVrshiw4AAAANgAAAAgAAAAAAAAAAAAAAKQBAAAAAG1ldGEuY3N2UEsBAhQAFAAACAgAe4V4XejkgV7DAAAAewEAAAgAAAAAAAAAAAAAAKQBXgAAAHNlZW4uY3N2UEsBAhQAFAAACAgAe4V4XcRiFUolAAAAJgAAAAkAAAAAAAAAAAAAAKQBRwEAAGxpa2VzLmNzdlBLAQIUABQAAAgIAHuFeF3pwU81dwAAAIwAAAARAAAAAAAAAAAAAACkAZMBAABub3RpZmljYXRpb25zLmNzdlBLAQIUABQAAAgIAHuFeF3hSepQYAAAAH4AAAAJAAAAAAAAAAAAAACkATkCAABsaXN0cy5jc3ZQSwECFAAUAAAICAB7hXhd8/H0o38AAACbAAAADAAAAAAAAAAAAAAApAHAAgAAcXVpY2thZGQuY3N2UEsFBgAAAAAGAAYAUwEAAGkDAAAAAA==',
};
