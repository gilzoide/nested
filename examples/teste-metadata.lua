local nested = require 'nested'

local t = nested.decode('1 2 3 a:a b:b c:c [g h i: [j k]]')

print(nested.encode(t, false))
print(nested.get(t, 4, 2))
print(nested.get(t, {2}))
print(nested.get(t, 2))
print(nested.get(t, 4, 'i', 1, 5, 6))
print(nested.get_or_create(t, 'keypath', 'create', 'successfully'))

for kp, v, parent in nested.iterate(t, { include_kv = true, table_only = false, skip_root = true }) do
    print(#kp, table.concat(kp, ' '), parent, v)
end

print(nested.set(t, 'invalid', 'keypath', false))
print(nested.set_or_create(t, 'another', 'keypath', 'created', true))
print(nested.set(t, 'b', 4))
print(nested.set(t, {'c'}, 7))
print(nested.set(t, 'a', nil))
print(nested.encode(t, false))