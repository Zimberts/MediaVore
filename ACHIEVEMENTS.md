# MediaVore Achievements

This document lists all the achievements available in MediaVore and how to unlock them.

## Current Achievements

### 🎬 Movies
| Title | Description | ID | Milestone |
|-------|-------------|----|-----------|
| **Movie Starter** | Watch your first movie | `movie_1` | 1 Movie |
| **Movie Enthusiast** | Watch 10 movies | `movie_10` | 10 Movies |
| **Film Fanatic** | Watch 50 movies | `movie_50` | 50 Movies |
| **Cinema Buff** | Watch 100 movies | `movie_100` | 100 Movies |
| **Cinema Legend** | Watch 500 movies | `movie_500` | 500 Movies |
| **Cinematic Guru** | Watch 1000 movies | `movie_1000` | 1000 Movies |

### 📺 TV Shows
| Title | Description | ID | Milestone |
|-------|-------------|----|-----------|
| **Series Starter** | Watch your first episode | `tv_1` | 1 Episode |
| **TV Regular** | Watch 50 episodes | `tv_50` | 50 Episodes |
| **Binge Watcher** | Watch 250 episodes | `tv_250` | 250 Episodes |
| **TV Master** | Watch 1000 episodes | `tv_1000` | 1000 Episodes |
| **TV Addict** | Watch 5000 episodes | `tv_5000` | 5000 Episodes |

### 🔄 Repeat Viewing
| Title | Description | ID | Milestone |
|-------|-------------|----|-----------|
| **Encore!** | Rewatch a classic | `rewatch_movie_2` | Watch the same movie twice |
| **Obsessed** | Can't get enough | `rewatch_movie_5` | Watch the same movie 5 times |
| **Double Take** | Reliving the moments | `rewatch_ep_2` | Watch the same episode twice |

### 🎭 Genre Mastery
| Title | Description | ID | Milestone |
|-------|-------------|----|-----------|
| **Scream Queen/King** | Horror fan | `genre_horror` | 10 Horror |
| **Horror Harvester** | Master of fright | `genre_horror_50` | 50 Horror |
| **Laugh Riot** | Comedy lover | `genre_comedy` | 20 Comedy |
| **King of Comedy** | Legend of laughs | `genre_comedy_100` | 100 Comedy |
| **Adrenaline Junkie** | Action fan | `genre_action` | 20 Action |
| **Future Explorer** | Sci-fi fan | `genre_scifi` | 20 Sci-Fi |
| **Scholar** | Documentary fan | `genre_doc` | 10 Docs |
| **Hopeless Romantic** | Romance fan | `genre_romance` | 15 Romance |

### 🌙 Behavioral & Specials
| Title | Description | ID | Milestone |
|-------|-------------|----|-----------|
| **Night Owl** | Burning the midnight oil | `night_owl` | 10 items between 12 AM - 4 AM |
| **Creature of the Night** | True vampire | `night_owl_100` | 100 items between 12 AM - 4 AM |
| **Weekend Warrior** | Weekend binge session | `weekend_warrior` | 15 items in any 72-hour window |
| **Marathon Runner** | Same show marathon | `marathon` | 10 episodes of one show in 24 hours |
| **Marathon Pro** | Ultimate marathoner | `marathon_pro` | 20 episodes of one show in 24 hours |
| **Consistent** | Building a habit | `streak_7` | Watch something 7 days in a row |
| **Dedicated** | Unstoppable streak | `streak_30` | Watch something 30 days in a row |

### ⏳ Time Investment
| Title | Description | ID | Milestone |
|-------|-------------|----|-----------|
| **1000 Minutes Club** | Getting started | `runtime_1000` | 1,000 Total Minutes |
| **Seasoned Viewer** | Getting serious | `runtime_hour_100` | 100 Total Hours |
| **10,000 Minutes Club** | Dedicated viewer | `runtime_10000` | 10,000 Total Minutes |
| **Ten Day Marathon** | Binge king | `runtime_day_10` | 10 Total Days |
| **The Millennial** | Clocking in | `runtime_hour_1000` | 1,000 Total Hours |
| **100,000 Minutes Club** | Media Vore legend | `runtime_100000` | 100,000 Total Minutes |
| **Double Life** | One year of media | `runtime_year_1` | 1 Total Year |
## How it works

Achievements are calculated automatically based on your **Seen History**. 
- **Movies/Episodes**: Counted based on the type of entry.
- **Rewatches**: Detected by finding multiple entries with the same TMDB ID (and season/episode for TV).
- **Genres**: Tracked using TMDB genre data stored with each seen entry.
- **Runtime**: Uses the runtime recorded when you log a viewing.
- **Streaks**: Analyzes consecutive days of activity in your history.
- **Behavioral**: Analyzes the timestamps and frequencies of your logs.

When you reach a milestone, the achievement will unlock automatically and record the date of completion based on the specific entry that pushed you over the limit.
