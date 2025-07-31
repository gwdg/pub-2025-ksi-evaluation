# Shared functionality that is used in multiple python scripts.

_mapNames = {
    "baseline": "Baseline",
    "nerdctl-bypass4netns": "Bypass4netns",
    "nerdctl-slirp4netns": "Slirp4netns",
    "podman-pasta": "Pasta"
}


def map_approach_name(driver):
    if hasattr(driver, "__iter__"):
        return [_mapNames[a] for a in driver]
    return _mapNames[driver] if driver in _mapNames else driver


def colors(n: int) -> list:
    return ["#fc8405"] + ["#669fcc" for _ in range(n - 1)]
