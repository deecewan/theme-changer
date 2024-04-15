config := "debug" # or "release"

build configuration=config:
  swift build -c {{configuration}}

run: build
  swift run

plist := "~/Library/LaunchAgents/au.com.deecewan.ThemeChanger.plist"

install: (build "release")
  cp ./au.com.deecewan.ThemeChanger.plist {{plist}}
  sed -I'' -e 's|{cwd}|{{justfile_directory()}}|' {{plist}}
  launchctl load -wF {{plist}}
