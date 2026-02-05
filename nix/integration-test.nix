# expectations:
# - Entries are sorted by priority
# - Entries are found in tasks directory (in a git repo)
# - qflist lists only open tasks
# - TasksList formats the tasks like this: <{PRIORITY:03}> [{huid}] {title}
# - The telescope export doesn't error out (we can't really integration test
#   telescope any further using headless neovim)
{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    let
      makeTask =
        {
          huid,
          title,
          priority,
          state,
        }:
        lib.nameValuePair huid (
          pkgs.writeTextDir "TASK.md" "# ${title}\n\n- STATE: ${state}\n- PRIORITY: ${priority}\n"
        );

      fakeTasks = pkgs.linkFarm "fake-tasks" (
        lib.listToAttrs (
          lib.map makeTask [
            {
              huid = "20260204-123434";
              title = "Not so important task";
              state = "CLOSED";
              priority = "30";
            }
            {
              huid = "20260205-123456";
              title = "Very Important Task";
              state = "OPEN";
              priority = "100";
            }
            {
              huid = "20260201-123456";
              title = "Another open task";
              state = "OPEN";
              priority = "50";
            }
          ]
        )
      );

      luaTestDriver =
        builtins.toFile "test-tasks.nvim.lua"
          #lua
          ''
            local Task = require("tasks.task")
            local filters = require("tasks.filters")
            local cwd = vim.uv.cwd()

            local expected = {
              {
                huid = "20260205-123456",
                title = "Very Important Task",
                state = "OPEN",
                priority = 100,
                task_dir = cwd .. "/tasks/20260205-123456",
                task_file = cwd .. "/tasks/20260205-123456/TASK.md",
              },
              {
                huid = "20260201-123456",
                title = "Another open task",
                state = "OPEN",
                priority = 50,
                task_dir = cwd .. "/tasks/20260201-123456",
                task_file = cwd .. "/tasks/20260201-123456/TASK.md",
              },
              {
                huid = "20260204-123434",
                title = "Not so important task",
                state = "CLOSED",
                priority = 30,
                task_dir = cwd .. "/tasks/20260204-123434",
                task_file = cwd .. "/tasks/20260204-123434/TASK.md",
              },
            }

            local res = Task.list()

            function do_test(expected, res)
              local actual = {}
              -- strip metatables for equality check
              for _, task in ipairs(res) do
                table.insert(actual, setmetatable(task, nil))
              end

              print(("expected = \n%s\n"):format(vim.inspect(expected)))
              print(("actual = \n%s\n"):format(vim.inspect(actual)))
              assert(vim.deep_equal(expected, actual))

              print("passed!")
            end

            do_test(expected, res)

            -- first two entries are open, so the last one is expected to be filtered out
            res = Task.list(filters.is_open)
            expected = { expected[1], expected[2] }

            do_test(expected, res)

            print("testing telescope...")
            require("telescope._extensions.tasks").exports.tasks()

            print("testing qflist...")
            require("tasks").qf_list()
            assert(vim.fn.getqflist()[1].text == "# Very Important Task")
            assert(vim.fn.getqflist()[2].text == "# Another open task")
          '';
    in
    {
      checks.integration =
        pkgs.runCommand "tasks.nvim-integration-test"
          {
            nativeBuildInputs = [
              self'.packages.default
              pkgs.coreutils
              pkgs.xxd
            ];
            passthru = { inherit fakeTasks; };
          }
          ''
            HOME=`mktemp -d`
            cd `mktemp -d`
            cp -r ${fakeTasks} tasks
            # to trick the plugin into believing this is a git repo
            mkdir .git

            output="$(nvim --headless +TasksList +qa! 2>&1)"
            expected=$'<100> [20260205-123456] Very Important Task\r\n<050> [20260201-123456] Another open task\r'
            if ! [ "$output" == "$expected" ]; then
              echo "expected:"
              echo
              echo -n "$expected" | xxd
              echo "actual:"
              echo
              echo -n "$output" | xxd
              exit 1
            fi
            nvim -l ${luaTestDriver}

            touch $out
          '';
    };
}
