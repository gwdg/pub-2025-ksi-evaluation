# Shared functionality that is used in multiple python scripts.

_mapNames = {
    "slurm": "Bare Metal",
    "ksi": "KSI",
    "hpk": "HPK",
    "bridge-operator": "Bridge-Operator"
}


def map_approach_name(project):
    if hasattr(project, "__iter__"):
        return [_mapNames[a] for a in project]
    return _mapNames[project] if project in _mapNames else project


def colors(n: int) -> list:
    return ["#fc8405"] + ["#669fcc" for _ in range(n - 1)]
