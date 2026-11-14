# Bundled fonts

Static font files, loaded offline (declared in `pubspec.yaml`). Both families
are under the SIL Open Font License 1.1; each folder holds its `OFL.txt`.

| Family | Files | Source |
| --- | --- | --- |
| Inter | `Inter-{Regular,Medium,SemiBold,Bold}.ttf` (400, 500, 600, 700) | Static files of the [Inter 4.1 release](https://github.com/rsms/inter/releases/tag/v4.1) (`extras/ttf/`), unmodified. |
| Bricolage Grotesque | `BricolageGrotesque24pt-{Medium,Bold}.ttf` (500, 700) | Instances of the variable font published in [google/fonts](https://github.com/google/fonts/tree/main/ofl/bricolagegrotesque), pinned at optical size 24 and width 100. |

Flutter does not apply the optical-size axis by itself, hence the pinned
instances. To regenerate them with [fontTools](https://github.com/fonttools/fonttools):

```bash
for w in 500:Medium 700:Bold; do
  fonttools varLib.instancer "BricolageGrotesque[opsz,wdth,wght].ttf" \
    opsz=24 wdth=100 wght=${w%%:*} --update-name-table \
    -o "BricolageGrotesque24pt-${w##*:}.ttf"
done
```
