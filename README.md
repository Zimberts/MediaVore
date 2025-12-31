# MediaVore

An app to keep track of movies/series/books seen/read or to watch/to read

## Participate

Use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)

\<type>(\<scope>): \<description>

The main types are `feat`, `fix`, `chore`, `bump`

The main scopes at the moment are `README`, `back`, `front`

## Product description

The aim of MediaVore is to record movies/series/books read/seen or which you want to.

At first the app will be stand alone (no server) but might evolve in the end.

For more details, the app will be split between books and movies/series (will start by the movies part, then series and will end with books).

### Movies/Series

- [ ] You'll have the possibility to fetch movies you want based on their name and year (at first).

- [ ] Then add them to your main watchlist (ordered by date added, but can be changed in front)

- [ ] Or add them to another Named list ordered by choice (not date added)

- [ ] Once you have seen them you enter manually with date seen, rating

- [ ] Possibility to import through csv

- [ ] get the platform where you can whatch it

- [ ] add a movie that is not published, send a notification / reminder when it'll be publish
  (same for series when a new episode gets out)

### Books

- [ ] Just like the movies and series, you have the possibility to record a book you have read or you want to read

Books data:

- Time of finish (if set as read)
- Rating on how you liked the book
- Number of the books (for series) (example 0 and number / -1 and 0 based number)

Additional features:

- [ ] (might add possibility to enter the time it took to read the book)
- [ ] Add a book by scanning its barcode
