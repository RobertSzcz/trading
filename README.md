# Trading

## Requirements
Erlang and Elixir versions are listed in .tool-versions file

## Setup
Run `mix escript.build` to build project
Now you can use exacutable `trading` that accepts transactions list and `fifo` `hifo` policies

Examples:
```
$ echo -e '2021-01-01,buy,10000.00,1.00000000\n2021-02-01,sell,20000.00,0.50000000' | ./trading fifo
```

```
$ echo -e '2021-01-01,buy,10000.00,1.00000000\n2021-01-02,buy,20000.00,1.00000000\n2021-02-01,sell,20000.00,1.50000000' | ./trading fifo
```

```
$ echo -e '2021-01-01,buy,10000.00,1.00000000\n2021-01-02,buy,20000.00,1.00000000\n2021-02-01,sell,20000.00,1.50000000' | ./trading hifo
```

## Notes:
- task was implemented assuming `an ordered transaction log`
