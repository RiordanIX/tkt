# tkt

A shell ticketing system.

There are 2 options to get the ticketing system to work:

1. Create `/tickets/open/` and `/tickets/closed`, and make the directories
	 user/group writable.
  For example:
	```
	sudo mkdir -p /tickets/open/ /tickets/closed/
	sudo chown <group>:<user> /tickets/open /tickets/closed
	```

2. Change the `TKTDIR` variable to the directory you want tickets to be
	 stored. As long as you have permissions to read and write, `tkt` will
	 create the necessary directories for you.

## Recommendations

Try renaming `tkt.sh` to `tkt` and moving/copying it to somewhere
in your system `PATH`, or add the directory `tkt` is stored to the `PATH`.

Feel free to make a feature request.
