local ok, cmp = pcall(require, "cmp")
if ok then
    cmp.register_source("tasks", require("tasks.cmp_source"):new())
end
