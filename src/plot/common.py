# Shared functionality that is used in multiple python scripts.

_mapNames = {
    "slurm": "bare metal",
    "ksi": "KSI",
    "hpk": "HPK",
    "bridge-operator": "Bridge-Operator"
}


def map_approach_name(project):
    if hasattr(project, "__iter__"):
        return [_mapNames[a] for a in project]
    return _mapNames[project]
