# Do not error out when some tasks are invalid

- STATE: CLOSED
- PRIORITY: 80

Currently, when for example the tasks directory contains a task where the title
isn't set (first line doesn't start with `# `), the telescope picker fails and
goto fails.

Fix: ../../lua/tasks/utils.lua M.list_tasks or M.get_task_title: skip files without a title

And probably in other places we need to be more lenient than returning nil and thus erroring out.
