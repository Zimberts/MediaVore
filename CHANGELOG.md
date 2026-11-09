# Changelog

Written by release-please from the Conventional Commits on `main` (see `DOCS/releasing.md`).
New entries are inserted above the latest one.

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
