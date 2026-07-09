---
name: load-task
description: Load taskwarrior task(s) into context to act on. Use when the user gives one or more task ids (or uuids) and wants you to work on them.
user-invocable: true
---

# load-task

Load taskwarrior task(s) into context so you can act on them, stripped of irrelevant metadata.

## Usage

Given one or more task ids (or uuids), run:

```bash
task <ids...> export | jq 'map({id,description,project,tags,priority,estimate,start,status,depends,annotations:(.annotations//[]|map(.description))}|with_entries(select(.value!=null and .value!=[] and .value!="")))'
```

`<ids...>` is space-separated (`task 42 7 13 export`). uuids work too.

## After loading

1. Act on the task(s). Multiple = handle each.
2. If a task has a non-empty `depends`, ask whether to load the dependency task(s) too — values are uuids; run `task <uuid> export | jq '...'` (same filter) on them. Do not load them silently.
3. Ask if anything is ambiguous.
