# Changelog

Written by release-please from the Conventional Commits on `main` (see `DOCS/releasing.md`).
New entries are inserted above the latest one.

## [1.4.2](https://github.com/Zimberts/MediaVore/compare/v1.4.1...v1.4.2) (2026-11-21)


### Bug fixes

* **media_details:** optimistically update seen status and streamline post-mark processing ([#355](https://github.com/Zimberts/MediaVore/issues/355)) ([#417](https://github.com/Zimberts/MediaVore/issues/417)) ([cc57880](https://github.com/Zimberts/MediaVore/commit/cc578808ea13d64747f5572679cccf4379dfd689))
* **memory:** dispose orphaned ChangeNotifiers and TextEditingControllers ([#382](https://github.com/Zimberts/MediaVore/issues/382)) ([#408](https://github.com/Zimberts/MediaVore/issues/408)) ([86586b2](https://github.com/Zimberts/MediaVore/commit/86586b20dfb09a1965baad47af29496713d8a887))
* **swipe:** route swiper decisions through LibraryProvider to refresh library and home ([#390](https://github.com/Zimberts/MediaVore/issues/390)) ([#416](https://github.com/Zimberts/MediaVore/issues/416)) ([4f73548](https://github.com/Zimberts/MediaVore/commit/4f7354877457b592cdd7a2ae426b89f9bbcb63d1))

## [1.4.1](https://github.com/Zimberts/MediaVore/compare/v1.4.0...v1.4.1) (2026-11-20)


### Bug fixes

* **i18n:** adapt viewing date input and display format to active locale ([#389](https://github.com/Zimberts/MediaVore/issues/389)) ([#401](https://github.com/Zimberts/MediaVore/issues/401)) ([0a6400f](https://github.com/Zimberts/MediaVore/commit/0a6400f1e6dc37c610809d8c64b22d7d818c9209))
* **lint:** replace deprecated Share and onReorder APIs and guard async context ([#388](https://github.com/Zimberts/MediaVore/issues/388)) ([#400](https://github.com/Zimberts/MediaVore/issues/400)) ([5d810ce](https://github.com/Zimberts/MediaVore/commit/5d810cec16b0f5252f8c536a6847ae93eb258ba1))
* **profile:** remove duplicate achievements and storage navigation routes from settings ([#392](https://github.com/Zimberts/MediaVore/issues/392)) ([#402](https://github.com/Zimberts/MediaVore/issues/402)) ([8d80981](https://github.com/Zimberts/MediaVore/commit/8d8098161ef0b4a463e822a5dff310e29707b613))
* **settings:** connect swipe discovery switch to show and hide swipe mode ([#393](https://github.com/Zimberts/MediaVore/issues/393)) ([#403](https://github.com/Zimberts/MediaVore/issues/403)) ([3b664fe](https://github.com/Zimberts/MediaVore/commit/3b664fe00ee01292c50c03947666300197817a05))


### Performance

* **export:** offload zip decompression and csv parsing to background isolate ([#384](https://github.com/Zimberts/MediaVore/issues/384)) ([#404](https://github.com/Zimberts/MediaVore/issues/404)) ([901572c](https://github.com/Zimberts/MediaVore/commit/901572c880587b12d60862e4ff7dff85b29347a6))
* **isar:** add composite and single indexes on SeenItemModel and QuickAdd models ([#383](https://github.com/Zimberts/MediaVore/issues/383)) ([#398](https://github.com/Zimberts/MediaVore/issues/398)) ([f838b80](https://github.com/Zimberts/MediaVore/commit/f838b801d6e5e04bc7c6166a20f8d9d831d54f55))

## [1.4.0](https://github.com/Zimberts/MediaVore/compare/v1.3.0...v1.4.0) (2026-11-19)


### Features

* **achievements:** categories and V1 presentation (tier badges, level sheet) ([#335](https://github.com/Zimberts/MediaVore/issues/335)) ([#364](https://github.com/Zimberts/MediaVore/issues/364)) ([779505e](https://github.com/Zimberts/MediaVore/commit/779505ebb0537cc91ea486ffe6cb3c6c0ade510b))
* **achievements:** discovery and together achievements ([#336](https://github.com/Zimberts/MediaVore/issues/336)) ([#373](https://github.com/Zimberts/MediaVore/issues/373)) ([a49b3fc](https://github.com/Zimberts/MediaVore/commit/a49b3fcafffa2215cce78054b47793e18d75eb27))
* **discovery:** because you watched personalized row in explore ([#310](https://github.com/Zimberts/MediaVore/issues/310)) ([#369](https://github.com/Zimberts/MediaVore/issues/369)) ([38ca40a](https://github.com/Zimberts/MediaVore/commit/38ca40aabbd49f06765742ca2138352ea222ab6e))
* **discovery:** Explore mode with permanent search and trending ([#307](https://github.com/Zimberts/MediaVore/issues/307)) ([#342](https://github.com/Zimberts/MediaVore/issues/342)) ([15fddba](https://github.com/Zimberts/MediaVore/commit/15fddbafc571115e133c1933ea6dd576b355b137))
* **front:** shared design components and unified action feedback ([#302](https://github.com/Zimberts/MediaVore/issues/302)) ([#339](https://github.com/Zimberts/MediaVore/issues/339)) ([f6e4c6d](https://github.com/Zimberts/MediaVore/commit/f6e4c6de74c45c3bc098288f2db75ea2c00b3711))
* **history:** history V1, daily grouping, library mode, and action menu ([#313](https://github.com/Zimberts/MediaVore/issues/313)) ([#353](https://github.com/Zimberts/MediaVore/issues/353)) ([6d49e91](https://github.com/Zimberts/MediaVore/commit/6d49e9115f9b5233a6a669469a88e61a0077e3f7))
* **home:** "In Progress" page with filters, sorting, dismissed series, and debug ([#305](https://github.com/Zimberts/MediaVore/issues/305)) ([#345](https://github.com/Zimberts/MediaVore/issues/345)) ([189909c](https://github.com/Zimberts/MediaVore/commit/189909c9b690e5d1471789f232473dbeb379b620))
* **home:** "Upcoming" grouped by period, monthly page, and remove Alerts screen ([#306](https://github.com/Zimberts/MediaVore/issues/306)) ([#346](https://github.com/Zimberts/MediaVore/issues/346)) ([c6d5a25](https://github.com/Zimberts/MediaVore/commit/c6d5a2502f1932ce8a8479a947d07c0fadfa17b7))
* **home:** Home "Tonight" screen ([#304](https://github.com/Zimberts/MediaVore/issues/304)) ([#341](https://github.com/Zimberts/MediaVore/issues/341)) ([1784457](https://github.com/Zimberts/MediaVore/commit/1784457efdbc20ad03a9d594e59d3cd133125d26))
* **library:** Library tab with lists overview and media type filter ([#311](https://github.com/Zimberts/MediaVore/issues/311)) ([#343](https://github.com/Zimberts/MediaVore/issues/343)) ([bb87162](https://github.com/Zimberts/MediaVore/commit/bb87162efb408ed0f4fde479bfd723a96a16cf9d))
* **library:** list page V1, sorting, display, selection, and sharing ([#312](https://github.com/Zimberts/MediaVore/issues/312)) ([#352](https://github.com/Zimberts/MediaVore/issues/352)) ([3d0e944](https://github.com/Zimberts/MediaVore/commit/3d0e94447c335bb6fede168c8ac5ae30edb32524))
* **lists:** compact format and serverless list intersection ([#286](https://github.com/Zimberts/MediaVore/issues/286)) ([#366](https://github.com/Zimberts/MediaVore/issues/366)) ([e2c437c](https://github.com/Zimberts/MediaVore/commit/e2c437c312b6788bd898a15bfab36a83b1619163))
* **media_details:** "Where to Watch" provider icons with JustWatch attribution ([#315](https://github.com/Zimberts/MediaVore/issues/315)) ([#357](https://github.com/Zimberts/MediaVore/issues/357)) ([8fc89a1](https://github.com/Zimberts/MediaVore/commit/8fc89a12d9bb79fa975d884b0b28f0399dd5bbb0))
* **media_details:** collapsible seasons V1 (durations, progress, episode checklist) ([#318](https://github.com/Zimberts/MediaVore/issues/318)) ([#360](https://github.com/Zimberts/MediaVore/issues/360)) ([4e3e5c1](https://github.com/Zimberts/MediaVore/commit/4e3e5c153c549ac1aff9c25678c10902f6dc30fc))
* **media_details:** full-page media detail, header, split list button, and section structure ([#314](https://github.com/Zimberts/MediaVore/issues/314)) ([#344](https://github.com/Zimberts/MediaVore/issues/344)) ([279a393](https://github.com/Zimberts/MediaVore/commit/279a393f252ebb321d48648cfa92b1563662cc74))
* **media_details:** person pages and clickable cast ([#316](https://github.com/Zimberts/MediaVore/issues/316)) ([#358](https://github.com/Zimberts/MediaVore/issues/358)) ([06d6632](https://github.com/Zimberts/MediaVore/commit/06d6632898472061fdb7b2f40512543d41eefa4c))
* **media_details:** previous unseen episodes prompt, "remember choice", and setting ([#320](https://github.com/Zimberts/MediaVore/issues/320)) ([#356](https://github.com/Zimberts/MediaVore/issues/356)) ([d4fec94](https://github.com/Zimberts/MediaVore/commit/d4fec94fc82b07e1d130ca51f163e817bdf6e4dd))
* **media_details:** rewatch series full cycle ([#321](https://github.com/Zimberts/MediaVore/issues/321)) ([#370](https://github.com/Zimberts/MediaVore/issues/370)) ([774d0f3](https://github.com/Zimberts/MediaVore/commit/774d0f3bb18001ccb3ae06bd7354aaabe90ce5ff))
* **media_details:** Saga collection section and adding missing movies ([#317](https://github.com/Zimberts/MediaVore/issues/317)) ([#359](https://github.com/Zimberts/MediaVore/issues/359)) ([1feb769](https://github.com/Zimberts/MediaVore/commit/1feb7694d0784c586087d49e062710857e924d30))
* **media_details:** simplified "seen" marking and Advanced Mode (editable dates and watches) ([#319](https://github.com/Zimberts/MediaVore/issues/319)) ([#354](https://github.com/Zimberts/MediaVore/issues/354)) ([c648fb5](https://github.com/Zimberts/MediaVore/commit/c648fb54a732078fb2a1560db2574ff327e7ed27))
* **navigation:** five-tab shell Home, Discover, Library, Together, Me ([#303](https://github.com/Zimberts/MediaVore/issues/303)) ([#340](https://github.com/Zimberts/MediaVore/issues/340)) ([54d4dfc](https://github.com/Zimberts/MediaVore/commit/54d4dfcdba6f06ed39dffc0756b77a625455e9fc))
* **profile:** Me tab (summary metrics, achievements preview, settings access) ([#332](https://github.com/Zimberts/MediaVore/issues/332)) ([#362](https://github.com/Zimberts/MediaVore/issues/362)) ([8cc4d14](https://github.com/Zimberts/MediaVore/commit/8cc4d146cc5e862032693d2e36f6de7a5eb19b7f))
* **search:** people search in discover explore mode ([#309](https://github.com/Zimberts/MediaVore/issues/309)) ([#368](https://github.com/Zimberts/MediaVore/issues/368)) ([609d3da](https://github.com/Zimberts/MediaVore/commit/609d3da2880336efa99c4c1c7d3e19cbbdb98fcd))
* **search:** search filters V1 (sort, decade, genres, rating, runtime, already seen) ([#308](https://github.com/Zimberts/MediaVore/issues/308)) ([#361](https://github.com/Zimberts/MediaVore/issues/361)) ([2695f20](https://github.com/Zimberts/MediaVore/commit/2695f20105b935f3bae717ca1748c636c95dbae7))
* **settings:** settings V1 with segmented controls and tracking ([#337](https://github.com/Zimberts/MediaVore/issues/337)) ([#374](https://github.com/Zimberts/MediaVore/issues/374)) ([f3ebe8e](https://github.com/Zimberts/MediaVore/commit/f3ebe8e31911a04558090cbad37eb997bab3604e))
* **stats:** Statistics page V1 (single scrollable page, periods, decades, series progress, lists) ([#333](https://github.com/Zimberts/MediaVore/issues/333)) ([#363](https://github.com/Zimberts/MediaVore/issues/363)) ([baf2b24](https://github.com/Zimberts/MediaVore/commit/baf2b2439fd3bffb9e62625adb888b34f1e2f561))
* **swipe:** optional swipe screen to discover and add movies to a list ([#285](https://github.com/Zimberts/MediaVore/issues/285)) ([#367](https://github.com/Zimberts/MediaVore/issues/367)) ([0380b83](https://github.com/Zimberts/MediaVore/commit/0380b8338437bc91d245808a3876c0fc041ca2d2))
* **theme:** design tokens, 6 palettes, and embedded fonts ([#301](https://github.com/Zimberts/MediaVore/issues/301)) ([#338](https://github.com/Zimberts/MediaVore/issues/338)) ([527b1f9](https://github.com/Zimberts/MediaVore/commit/527b1f9a2f42080f86fbb8d2526280468dd57e53))
* **together:** session setup, QR exchange and common titles ([#330](https://github.com/Zimberts/MediaVore/issues/330)) ([#371](https://github.com/Zimberts/MediaVore/issues/371)) ([20be58f](https://github.com/Zimberts/MediaVore/commit/20be58f9048551307341580fc9649da9c2498beb))
* **together:** vote by passing phone and tonight choice ([#331](https://github.com/Zimberts/MediaVore/issues/331)) ([#372](https://github.com/Zimberts/MediaVore/issues/372)) ([00e0a67](https://github.com/Zimberts/MediaVore/commit/00e0a67aea499a79fb13fbed0b8553bf4b05131d))


### Bug fixes

* **test:** mock previous unseen episodes and fix together tab label ([#378](https://github.com/Zimberts/MediaVore/issues/378)) ([ce64818](https://github.com/Zimberts/MediaVore/commit/ce648186f24dc79f67227f200e260214d890bdd1))
* **tmdb:** refresh incomplete cached metadata and fallback origin countries ([#287](https://github.com/Zimberts/MediaVore/issues/287), [#288](https://github.com/Zimberts/MediaVore/issues/288)) ([#365](https://github.com/Zimberts/MediaVore/issues/365)) ([b020ec8](https://github.com/Zimberts/MediaVore/commit/b020ec89e912b560fa8e392123b88e060e9b885e))

## [1.3.0](https://github.com/Zimberts/MediaVore/compare/v1.2.0...v1.3.0) (2026-11-09)


### Features

* **a11y:** add tooltips to icon-only buttons ([#208](https://github.com/Zimberts/MediaVore/issues/208)) ([#255](https://github.com/Zimberts/MediaVore/issues/255)) ([1b964a1](https://github.com/Zimberts/MediaVore/commit/1b964a1fc95c2b8c0dd9fbcf8f618c0388db0875))
* **achievements:** add the App usage category ([#229](https://github.com/Zimberts/MediaVore/issues/229)) ([#282](https://github.com/Zimberts/MediaVore/issues/282)) ([ab83018](https://github.com/Zimberts/MediaVore/commit/ab83018b5220702d8725730a7c0aaa25f947a302))
* **achievements:** add the Collection category ([#225](https://github.com/Zimberts/MediaVore/issues/225)) ([#260](https://github.com/Zimberts/MediaVore/issues/260)) ([33bdcac](https://github.com/Zimberts/MediaVore/commit/33bdcacbd0c783bf0b0c6d0a6c9f235984675362))
* **achievements:** add the Duration category ([#228](https://github.com/Zimberts/MediaVore/issues/228)) ([#263](https://github.com/Zimberts/MediaVore/issues/263)) ([aeb0abb](https://github.com/Zimberts/MediaVore/commit/aeb0abb83f7af9e39d93cfda5c3568ca44854f2a))
* **achievements:** add the Rhythm category ([#227](https://github.com/Zimberts/MediaVore/issues/227)) ([#262](https://github.com/Zimberts/MediaVore/issues/262)) ([0eb35ec](https://github.com/Zimberts/MediaVore/commit/0eb35ecfbb6b3a38bbe28362ba69269d3c99823c))
* **achievements:** family names, regular watch-time scale, weekend tiers ([#224](https://github.com/Zimberts/MediaVore/issues/224)) ([#258](https://github.com/Zimberts/MediaVore/issues/258)) ([c2f89df](https://github.com/Zimberts/MediaVore/commit/c2f89dfd106c3d0a82ccecf580a5df2ea749386a))
* **front:** declutter My Lists app bar and add a Profile tab ([#204](https://github.com/Zimberts/MediaVore/issues/204), [#205](https://github.com/Zimberts/MediaVore/issues/205)) ([#280](https://github.com/Zimberts/MediaVore/issues/280)) ([3562757](https://github.com/Zimberts/MediaVore/commit/3562757e0a26a1fb1018943839e93613d2c2f942))
* **front:** reusable empty state with help text and search action ([#201](https://github.com/Zimberts/MediaVore/issues/201)) ([#278](https://github.com/Zimberts/MediaVore/issues/278)) ([ea254f1](https://github.com/Zimberts/MediaVore/commit/ea254f14c70922d1b7f5c8698b2da70302e51ea8))
* **tmdb-onboarding:** guide and verify the TMDB key on first launch ([#259](https://github.com/Zimberts/MediaVore/issues/259)) ([c9eca22](https://github.com/Zimberts/MediaVore/commit/c9eca22b01076244f898ffc4a6dffd53aed69db7))


### Bug fixes

* **achievements:** reuse the open AchievementsPage on banner tap ([#257](https://github.com/Zimberts/MediaVore/issues/257)) ([83aee80](https://github.com/Zimberts/MediaVore/commit/83aee80019f4557414adf6386e2461a4f3f8af4a))
* **back:** auto-refresh returning series so new episodes are detected ([#173](https://github.com/Zimberts/MediaVore/issues/173)) ([063acca](https://github.com/Zimberts/MediaVore/commit/063accac4199c6880cd20d0f828f43e85cda60de))
* **deps:** migrate to file_picker 13 API (supersedes [#267](https://github.com/Zimberts/MediaVore/issues/267)) ([#268](https://github.com/Zimberts/MediaVore/issues/268)) ([3814581](https://github.com/Zimberts/MediaVore/commit/3814581d726a9cfc8aef2aaa7def29064f3ded85))
* **front:** refresh episode counters after Watch Next ([#209](https://github.com/Zimberts/MediaVore/issues/209)) ([#256](https://github.com/Zimberts/MediaVore/issues/256)) ([3a4a9af](https://github.com/Zimberts/MediaVore/commit/3a4a9af1999e800739667b12a8889189d67b0cd0))
* **navigation:** align bottom-nav labels with screen titles ([#202](https://github.com/Zimberts/MediaVore/issues/202)) ([#279](https://github.com/Zimberts/MediaVore/issues/279)) ([72032a9](https://github.com/Zimberts/MediaVore/commit/72032a91e01fecd896019e4e364f133845065ce3))
* **release:** skip the iOS job when no signing secret is set ([#277](https://github.com/Zimberts/MediaVore/issues/277)) ([51e92f8](https://github.com/Zimberts/MediaVore/commit/51e92f89f6a8b08aae25b37c257c909f9bd20b45))


### Performance

* **cache:** fetch details and seasons with append_to_response ([#212](https://github.com/Zimberts/MediaVore/issues/212)) ([#281](https://github.com/Zimberts/MediaVore/issues/281)) ([39ab091](https://github.com/Zimberts/MediaVore/commit/39ab091ac0fbc3cabbbd07df19d40238e75fb412))

## [1.2.0](https://github.com/Zimberts/MediaVore/compare/v1.1.0...v1.2.0) (2026-11-07)


### Features

* add runtime metadata support for TV shows and alerts ([#150](https://github.com/Zimberts/MediaVore/issues/150)) ([0ff0c19](https://github.com/Zimberts/MediaVore/commit/0ff0c196c9163bc36cd99cb0bd32b8ad0449d624))
* **front:** app language selection with localized TMDB data ([#189](https://github.com/Zimberts/MediaVore/issues/189)) ([a12528d](https://github.com/Zimberts/MediaVore/commit/a12528dca68f8d53dfe54ce951dae41de9cccd53))
* **front:** group tiered achievements and add new tiers ([#195](https://github.com/Zimberts/MediaVore/issues/195)) ([a078009](https://github.com/Zimberts/MediaVore/commit/a078009f0f10131e123809a8414ecc638c417e85))
* **front:** readable default export file name ([#233](https://github.com/Zimberts/MediaVore/issues/233)) ([#234](https://github.com/Zimberts/MediaVore/issues/234)) ([f06459f](https://github.com/Zimberts/MediaVore/commit/f06459f355797b54a48c782d99d2130ac3e24cde))
* **media_details:** implement reusable top scrim gradient for headers ([#157](https://github.com/Zimberts/MediaVore/issues/157)) ([e68ac8f](https://github.com/Zimberts/MediaVore/commit/e68ac8f40c1a45a80b1ff733b66bd39d464ec024))
* **notifications:** add diagnostic debug mode for Notification Center ([#153](https://github.com/Zimberts/MediaVore/issues/153)) ([07a9932](https://github.com/Zimberts/MediaVore/commit/07a9932fab9631194148ecddb04b4db15d464b9e))
* **notifications:** fix new episodes ([#155](https://github.com/Zimberts/MediaVore/issues/155)) ([ee8915e](https://github.com/Zimberts/MediaVore/commit/ee8915edecf8e394e4d7a339dd52280236c59cdf))
* **search:** preserve scroll position and improve reordering in `SavedMediaPage` ([#158](https://github.com/Zimberts/MediaVore/issues/158)) ([f6c2e60](https://github.com/Zimberts/MediaVore/commit/f6c2e609ba03cb5096ee12d31caaf57d384d136c))


### Bug fixes

* **back:** bound TMDB network usage (timeouts, 429 retry, enrichment, warm-up) ([#177](https://github.com/Zimberts/MediaVore/issues/177)) ([f588972](https://github.com/Zimberts/MediaVore/commit/f58897295227b6480db3000294cd6d8e091a4d87)), closes [#164](https://github.com/Zimberts/MediaVore/issues/164)
* **back:** declare UTF-8 byte sizes in export ZIP entries ([#196](https://github.com/Zimberts/MediaVore/issues/196)) ([06f5064](https://github.com/Zimberts/MediaVore/commit/06f5064179e7bc81b6ed59fa5e425b5cd9332287))
* **back:** enhance notification anchoring for TV series to prioritize aired unseen episodes ([#211](https://github.com/Zimberts/MediaVore/issues/211)) ([5797fdf](https://github.com/Zimberts/MediaVore/commit/5797fdf528f3ccd606c6ee97e814fc6d01df72c9))
* **back:** lazy-load MediaCache with bounded LRU and batched Isar writes ([#179](https://github.com/Zimberts/MediaVore/issues/179)) ([d4ebd29](https://github.com/Zimberts/MediaVore/commit/d4ebd29e493fd1fbd89a2ce10ffc8d607e5bce48)), closes [#165](https://github.com/Zimberts/MediaVore/issues/165)
* **back:** make data import atomic across all collections ([#174](https://github.com/Zimberts/MediaVore/issues/174)) ([3c88ac1](https://github.com/Zimberts/MediaVore/commit/3c88ac16e4bffd67b2885e8c4adbd49d7e406e76))
* **back:** make getMediaDetails resilient to optional endpoint failures ([#186](https://github.com/Zimberts/MediaVore/issues/186)) ([c65ef43](https://github.com/Zimberts/MediaVore/commit/c65ef4314a626de69539d1f63793c37a7f48ad90)), closes [#162](https://github.com/Zimberts/MediaVore/issues/162)
* **back:** map DioException consistently in MediaRemoteDataSource ([#178](https://github.com/Zimberts/MediaVore/issues/178)) ([96f8d52](https://github.com/Zimberts/MediaVore/commit/96f8d52273b5e87ff65343ad77dce9adc44bb70a)), closes [#163](https://github.com/Zimberts/MediaVore/issues/163)
* **back:** sign Android release builds with a real upload key ([#183](https://github.com/Zimberts/MediaVore/issues/183)) ([89e35e4](https://github.com/Zimberts/MediaVore/commit/89e35e482a44a7100c5418f43a4a00e9e53ee177))
* **back:** store TMDB credential in secure storage ([#171](https://github.com/Zimberts/MediaVore/issues/171)) ([#182](https://github.com/Zimberts/MediaVore/issues/182)) ([f84f559](https://github.com/Zimberts/MediaVore/commit/f84f559160779f5591eb48dd7f8513b5ebab0444))
* **back:** surface search/discover errors instead of empty results ([#176](https://github.com/Zimberts/MediaVore/issues/176)) ([74222c1](https://github.com/Zimberts/MediaVore/commit/74222c16415de6fb4431ce5018d110f20fe004bf)), closes [#161](https://github.com/Zimberts/MediaVore/issues/161)
* **back:** validate export/import archives ([#175](https://github.com/Zimberts/MediaVore/issues/175)) ([362f9c5](https://github.com/Zimberts/MediaVore/commit/362f9c5347c4fc3bcebca32ba594cf4275ec138a))
* **front:** harden startup bootstrap and add retry on init failure ([#181](https://github.com/Zimberts/MediaVore/issues/181)) ([d16080e](https://github.com/Zimberts/MediaVore/commit/d16080e4167f6add62d66c3bc23e61615eddfe2f)), closes [#170](https://github.com/Zimberts/MediaVore/issues/170)
* **front:** migrate iOS app to UIScene lifecycle ([#187](https://github.com/Zimberts/MediaVore/issues/187)) ([9ee2a0d](https://github.com/Zimberts/MediaVore/commit/9ee2a0d58e5d86b45209d35d6b8e1397a6c2cbb2))
* **release:** let release-please bump the version shown in About ([#266](https://github.com/Zimberts/MediaVore/issues/266)) ([1df8c7a](https://github.com/Zimberts/MediaVore/commit/1df8c7a489e8d3c3e5bfd4a5fca6309b101a5240))

## 1.1.0

Released before release-please: see the git history up to `chore: bump version to 1.1.0`.
