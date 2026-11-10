/// Offline sample catalog used to take screenshots of MediaVore.
///
/// Titles, years, genres and cast are those of real, well-known works so the
/// screenshots look plausible. Ratings, runtimes and episode lists are rounded
/// illustrative values, not live TMDB data. Overviews are written for this
/// demo. Every poster and photo is generated locally (see `demo_images.dart`):
/// no TMDB artwork is used.
library;

/// TMDB genre ids (subset) with their French and English names.
const demoGenres = <int, (String, String)>{
  12: ('Aventure', 'Adventure'),
  14: ('Fantastique', 'Fantasy'),
  16: ('Animation', 'Animation'),
  18: ('Drame', 'Drama'),
  28: ('Action', 'Action'),
  35: ('Comédie', 'Comedy'),
  36: ('Histoire', 'History'),
  53: ('Thriller', 'Thriller'),
  80: ('Crime', 'Crime'),
  878: ('Science-Fiction', 'Science Fiction'),
  9648: ('Mystère', 'Mystery'),
  10402: ('Musique', 'Music'),
  10749: ('Romance', 'Romance'),
  10759: ('Action & Aventure', 'Action & Adventure'),
  10765: ('Science-Fiction & Fantastique', 'Sci-Fi & Fantasy'),
};

class DemoPerson {
  const DemoPerson(this.id, this.name, this.birthday, this.placeOfBirth);

  final int id;
  final String name;
  final String birthday;
  final String placeOfBirth;
}

const demoPeople = <DemoPerson>[
  DemoPerson(1190668, 'Timothée Chalamet', '1995-12-27', 'New York, USA'),
  DemoPerson(505710, 'Zendaya', '1996-09-01', 'Oakland, USA'),
  DemoPerson(1373737, 'Florence Pugh', '1996-01-03', 'Oxford, UK'),
  DemoPerson(2037, 'Cillian Murphy', '1976-05-25', 'Douglas, Irlande'),
  DemoPerson(10297, 'Matthew McConaughey', '1969-11-04', 'Uvalde, USA'),
  DemoPerson(1083010, 'Jessica Chastain', '1977-03-24', 'Sacramento, USA'),
  DemoPerson(18997, 'Emma Stone', '1988-11-06', 'Scottsdale, USA'),
  DemoPerson(30614, 'Ryan Gosling', '1980-11-12', 'London, Canada'),
  DemoPerson(1625558, 'Michelle Yeoh', '1962-08-06', 'Ipoh, Malaisie'),
  DemoPerson(4491, 'Adam Scott', '1973-04-03', 'Santa Cruz, USA'),
  DemoPerson(1397778, 'Jeremy Allen White', '1991-02-17', 'New York, USA'),
  DemoPerson(17419, 'Bryan Cranston', '1956-03-07', 'Hollywood, USA'),
  DemoPerson(1245, 'Sandra Hüller', '1978-04-30', 'Suhl, Allemagne'),
  DemoPerson(1146, 'Omar Sy', '1978-01-20', 'Trappes, France'),
  DemoPerson(1592, 'Audrey Tautou', '1976-08-09', 'Beaumont, France'),
];

DemoPerson demoPerson(int id) => demoPeople.firstWhere((p) => p.id == id);

class DemoMedia {
  const DemoMedia({
    required this.id,
    required this.isTv,
    required this.titleFr,
    required this.titleEn,
    required this.originalTitle,
    required this.year,
    required this.genres,
    required this.rating,
    required this.voteCount,
    required this.runtime,
    required this.language,
    required this.country,
    required this.overviewFr,
    required this.overviewEn,
    required this.cast,
    this.director,
    this.popularity = 50,
    this.seasons = const [],
    this.collection,
  });

  final int id;
  final bool isTv;
  final String titleFr;
  final String titleEn;
  final String originalTitle;
  final int year;
  final List<int> genres;
  final double rating;
  final int voteCount;

  /// Movie runtime, or episode runtime for a series (minutes).
  final int runtime;
  final String language;
  final String country;
  final String overviewFr;
  final String overviewEn;

  /// (person id, character).
  final List<(int, String)> cast;
  final String? director;
  final double popularity;

  /// Episode count per season, for series. A negative count marks a season
  /// still airing: its last |count| / 2 episodes are in the future.
  final List<int> seasons;
  final (int, String)? collection;

  String get mediaType => isTv ? 'tv' : 'movie';
  String title(String lang) => lang == 'fr' ? titleFr : titleEn;
  String overview(String lang) => lang == 'fr' ? overviewFr : overviewEn;

  /// Fake TMDB image path, served by the screenshot HTTP stub.
  String get posterPath => '/demo/poster/$mediaType-$id.png';
  String get backdropPath => '/demo/backdrop/$mediaType-$id.png';
}

const demoCatalog = <DemoMedia>[
  DemoMedia(
    id: 693134,
    isTv: false,
    titleFr: 'Dune : Deuxième partie',
    titleEn: 'Dune: Part Two',
    originalTitle: 'Dune: Part Two',
    year: 2024,
    genres: [878, 12],
    rating: 8.1,
    voteCount: 6200,
    runtime: 167,
    language: 'en',
    country: 'US',
    popularity: 98,
    overviewFr:
        'Paul Atreides s’allie aux Fremen pour venger sa famille, tout en '
        'redoutant l’avenir qu’il entrevoit.',
    overviewEn:
        'Paul Atreides unites with the Fremen to avenge his family while '
        'fearing the future he foresees.',
    cast: [(1190668, 'Paul Atreides'), (505710, 'Chani'), (1373737, 'Irulan')],
    director: 'Denis Villeneuve',
    collection: (726871, 'Dune'),
  ),
  DemoMedia(
    id: 872585,
    isTv: false,
    titleFr: 'Oppenheimer',
    titleEn: 'Oppenheimer',
    originalTitle: 'Oppenheimer',
    year: 2023,
    genres: [18, 36],
    rating: 8.1,
    voteCount: 9800,
    runtime: 180,
    language: 'en',
    country: 'US',
    popularity: 90,
    overviewFr:
        'Le portrait du physicien qui dirigea le projet Manhattan, et du '
        'prix moral de son invention.',
    overviewEn:
        'A portrait of the physicist who led the Manhattan Project, and of '
        'the moral cost of his invention.',
    cast: [(2037, 'J. Robert Oppenheimer'), (1373737, 'Jean Tatlock')],
    director: 'Christopher Nolan',
  ),
  DemoMedia(
    id: 157336,
    isTv: false,
    titleFr: 'Interstellar',
    titleEn: 'Interstellar',
    originalTitle: 'Interstellar',
    year: 2014,
    genres: [878, 18, 12],
    rating: 8.4,
    voteCount: 36000,
    runtime: 169,
    language: 'en',
    country: 'US',
    popularity: 85,
    overviewFr:
        'Une équipe d’explorateurs traverse un trou de ver pour trouver une '
        'nouvelle planète habitable.',
    overviewEn:
        'A team of explorers travels through a wormhole to find a new '
        'habitable planet.',
    cast: [(10297, 'Cooper'), (1083010, 'Murph')],
    director: 'Christopher Nolan',
  ),
  DemoMedia(
    id: 129,
    isTv: false,
    titleFr: 'Le Voyage de Chihiro',
    titleEn: 'Spirited Away',
    originalTitle: '千と千尋の神隠し',
    year: 2001,
    genres: [16, 14],
    rating: 8.5,
    voteCount: 17000,
    runtime: 125,
    language: 'ja',
    country: 'JP',
    popularity: 70,
    overviewFr:
        'Égarée dans un monde d’esprits, une fillette travaille dans des '
        'bains magiques pour sauver ses parents.',
    overviewEn:
        'Lost in a world of spirits, a young girl works in a magical bathhouse '
        'to save her parents.',
    cast: [],
    director: 'Hayao Miyazaki',
  ),
  DemoMedia(
    id: 496243,
    isTv: false,
    titleFr: 'Parasite',
    titleEn: 'Parasite',
    originalTitle: '기생충',
    year: 2019,
    genres: [35, 53, 18],
    rating: 8.5,
    voteCount: 19000,
    runtime: 133,
    language: 'ko',
    country: 'KR',
    popularity: 72,
    overviewFr:
        'Une famille sans le sou s’infiltre peu à peu au service d’une riche '
        'famille de Séoul.',
    overviewEn:
        'A penniless family gradually worms its way into the household of a '
        'wealthy Seoul family.',
    cast: [],
    director: 'Bong Joon-ho',
  ),
  DemoMedia(
    id: 545611,
    isTv: false,
    titleFr: 'Everything Everywhere All at Once',
    titleEn: 'Everything Everywhere All at Once',
    originalTitle: 'Everything Everywhere All at Once',
    year: 2022,
    genres: [28, 12, 878],
    rating: 7.8,
    voteCount: 7000,
    runtime: 140,
    language: 'en',
    country: 'US',
    popularity: 60,
    overviewFr:
        'Une gérante de laverie découvre qu’elle doit sauver le multivers, '
        'entre deux déclarations d’impôts.',
    overviewEn:
        'A laundromat owner learns she must save the multiverse, between two '
        'tax returns.',
    cast: [(1625558, 'Evelyn Wang')],
    director: 'Daniel Kwan, Daniel Scheinert',
  ),
  DemoMedia(
    id: 313369,
    isTv: false,
    titleFr: 'La La Land',
    titleEn: 'La La Land',
    originalTitle: 'La La Land',
    year: 2016,
    genres: [35, 18, 10749, 10402],
    rating: 7.9,
    voteCount: 17000,
    runtime: 128,
    language: 'en',
    country: 'US',
    popularity: 55,
    overviewFr:
        'À Los Angeles, une actrice et un pianiste de jazz s’aiment en '
        'poursuivant chacun leur rêve.',
    overviewEn:
        'In Los Angeles, an actress and a jazz pianist fall in love while '
        'chasing their own dreams.',
    cast: [(18997, 'Mia'), (30614, 'Sebastian')],
    director: 'Damien Chazelle',
  ),
  DemoMedia(
    id: 329865,
    isTv: false,
    titleFr: 'Premier Contact',
    titleEn: 'Arrival',
    originalTitle: 'Arrival',
    year: 2016,
    genres: [18, 878, 9648],
    rating: 7.6,
    voteCount: 18000,
    runtime: 116,
    language: 'en',
    country: 'US',
    popularity: 50,
    overviewFr:
        'Une linguiste tente de communiquer avec des visiteurs venus '
        'd’ailleurs avant que le monde ne s’embrase.',
    overviewEn:
        'A linguist tries to communicate with visitors from elsewhere before '
        'the world goes to war.',
    cast: [],
    director: 'Denis Villeneuve',
  ),
  DemoMedia(
    id: 915935,
    isTv: false,
    titleFr: 'Anatomie d’une chute',
    titleEn: 'Anatomy of a Fall',
    originalTitle: 'Anatomie d’une chute',
    year: 2023,
    genres: [80, 18, 9648],
    rating: 7.7,
    voteCount: 2400,
    runtime: 151,
    language: 'fr',
    country: 'FR',
    popularity: 45,
    overviewFr:
        'Accusée de la mort de son mari, une romancière voit son couple '
        'disséqué lors du procès.',
    overviewEn:
        'Accused of her husband’s death, a novelist sees her marriage '
        'dissected at trial.',
    cast: [(1245, 'Sandra Voyter')],
    director: 'Justine Triet',
  ),
  DemoMedia(
    id: 77338,
    isTv: false,
    titleFr: 'Intouchables',
    titleEn: 'The Intouchables',
    originalTitle: 'Intouchables',
    year: 2011,
    genres: [18, 35],
    rating: 8.3,
    voteCount: 17500,
    runtime: 112,
    language: 'fr',
    country: 'FR',
    popularity: 40,
    overviewFr:
        'Un aristocrate tétraplégique engage un jeune de banlieue comme aide '
        'à domicile. Une amitié improbable naît.',
    overviewEn:
        'A quadriplegic aristocrat hires a young man from the suburbs as his '
        'caregiver. An unlikely friendship is born.',
    cast: [(1146, 'Driss')],
    director: 'Olivier Nakache, Éric Toledano',
  ),
  DemoMedia(
    id: 194,
    isTv: false,
    titleFr: 'Le Fabuleux Destin d’Amélie Poulain',
    titleEn: 'Amélie',
    originalTitle: 'Le Fabuleux Destin d’Amélie Poulain',
    year: 2001,
    genres: [35, 10749],
    rating: 7.9,
    voteCount: 11000,
    runtime: 122,
    language: 'fr',
    country: 'FR',
    popularity: 38,
    overviewFr:
        'À Montmartre, une serveuse rêveuse décide de faire le bonheur des '
        'autres, en secret.',
    overviewEn:
        'In Montmartre, a dreamy waitress decides to secretly bring happiness '
        'to others.',
    cast: [(1592, 'Amélie Poulain')],
    director: 'Jean-Pierre Jeunet',
  ),
  DemoMedia(
    id: 95396,
    isTv: true,
    titleFr: 'Severance',
    titleEn: 'Severance',
    originalTitle: 'Severance',
    year: 2022,
    genres: [18, 9648, 10765],
    rating: 8.4,
    voteCount: 2500,
    runtime: 50,
    language: 'en',
    country: 'US',
    popularity: 80,
    seasons: [9, -10],
    overviewFr:
        'Chez Lumon, des employés ont accepté que leurs souvenirs de bureau '
        'soient séparés de leur vie privée.',
    overviewEn:
        'At Lumon, employees have agreed to have their work memories severed '
        'from their private lives.',
    cast: [(4491, 'Mark Scout')],
  ),
  DemoMedia(
    id: 136315,
    isTv: true,
    titleFr: 'The Bear',
    titleEn: 'The Bear',
    originalTitle: 'The Bear',
    year: 2022,
    genres: [35, 18],
    rating: 8.2,
    voteCount: 1300,
    runtime: 32,
    language: 'en',
    country: 'US',
    popularity: 65,
    seasons: [8, 10, 10],
    overviewFr:
        'Un jeune chef étoilé reprend la sandwicherie familiale de Chicago '
        'après un drame.',
    overviewEn:
        'A young fine-dining chef takes over his family’s Chicago sandwich '
        'shop after a tragedy.',
    cast: [(1397778, 'Carmen Berzatto')],
  ),
  DemoMedia(
    id: 94605,
    isTv: true,
    titleFr: 'Arcane',
    titleEn: 'Arcane',
    originalTitle: 'Arcane',
    year: 2021,
    genres: [16, 10765, 10759],
    rating: 8.8,
    voteCount: 4800,
    runtime: 40,
    language: 'en',
    country: 'FR',
    popularity: 60,
    seasons: [9, 9],
    overviewFr:
        'Deux sœurs s’opposent dans le conflit qui déchire la cité de '
        'Piltover et ses bas-fonds.',
    overviewEn:
        'Two sisters end up on opposite sides of the conflict tearing apart '
        'Piltover and its undercity.',
    cast: [],
  ),
  DemoMedia(
    id: 1396,
    isTv: true,
    titleFr: 'Breaking Bad',
    titleEn: 'Breaking Bad',
    originalTitle: 'Breaking Bad',
    year: 2008,
    genres: [18, 80],
    rating: 8.9,
    voteCount: 15000,
    runtime: 47,
    language: 'en',
    country: 'US',
    popularity: 75,
    seasons: [7, 13, 13, 13, 16],
    overviewFr:
        'Un professeur de chimie atteint d’un cancer se lance dans la '
        'fabrication de drogue pour assurer l’avenir des siens.',
    overviewEn:
        'A chemistry teacher diagnosed with cancer turns to making drugs to '
        'secure his family’s future.',
    cast: [(17419, 'Walter White')],
  ),
  DemoMedia(
    id: 70523,
    isTv: true,
    titleFr: 'Dark',
    titleEn: 'Dark',
    originalTitle: 'Dark',
    year: 2017,
    genres: [80, 18, 9648, 10765],
    rating: 8.4,
    voteCount: 7000,
    runtime: 55,
    language: 'de',
    country: 'DE',
    popularity: 50,
    seasons: [10, 8, 8],
    overviewFr:
        'La disparition d’un enfant révèle les secrets de quatre familles '
        'd’une petite ville allemande, sur plusieurs époques.',
    overviewEn:
        'A child’s disappearance exposes the secrets of four families in a '
        'small German town, across several eras.',
    cast: [],
  ),
];

DemoMedia? demoMedia(String type, int id) {
  for (final m in demoCatalog) {
    if (m.id == id && m.mediaType == type) return m;
  }
  return null;
}
