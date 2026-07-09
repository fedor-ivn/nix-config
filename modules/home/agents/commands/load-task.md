---
description: Load taskwarrior task(s) into context to act on
allowed-tools: Bash(task:*), Bash(jq:*)
argument-hint: <id> [more ids...]
---
Tasks loaded:

!`task $ARGUMENTS export | jq 'map({id,description,project,tags,priority,estimate,start,status,depends,annotations:(.annotations//[]|map(.description))}|with_entries(select(.value!=null and .value!=[] and .value!="")))'`

Act on the above task(s). Multiple = handle each.

If a task has a non-empty `depends`, ask whether to load the dependency task(s) too (values are uuids; run `task <uuid> export` or this command on them). Do not load them silently.

Ask if anything is ambiguous.
