#
# @TEST-EXEC: cp input1.log input.log
# @TEST-EXEC: btest-bg-run bro bro %INPUT 
# @TEST-EXEC: sleep 3
# @TEST-EXEC: cp input2.log input.log
# @TEST-EXEC: sleep 3
# @TEST-EXEC: cp input3.log input.log
# @TEST-EXEC: btest-bg-wait -k 5
# @TEST-EXEC: btest-diff out

@TEST-START-FILE input1.log
#separator \x09
#path	ssh
#fields	b	i	e	c	p	sn	a	d	t	iv	s	sc	ss	se	vc	ve	f
#types	bool	int	enum	count	port	subnet	addr	double	time	interval	string	table	table	table	vector	vector	func
T	-42	SSH::LOG	21	123	10.0.0.0/24	1.2.3.4	3.14	1315801931.273616	100.000000	hurz	2,4,1,3	CC,AA,BB	EMPTY	10,20,30	EMPTY	SSH::foo\x0a{ \x0aif (0 < SSH::i) \x0a\x09return (Foo);\x0aelse\x0a\x09return (Bar);\x0a\x0a}
@TEST-END-FILE
@TEST-START-FILE input2.log
#separator \x09
#path	ssh
#fields	b	i	e	c	p	sn	a	d	t	iv	s	sc	ss	se	vc	ve	f
#types	bool	int	enum	count	port	subnet	addr	double	time	interval	string	table	table	table	vector	vector	func
T	-42	SSH::LOG	21	123	10.0.0.0/24	1.2.3.4	3.14	1315801931.273616	100.000000	hurz	2,4,1,3	CC,AA,BB	EMPTY	10,20,30	EMPTY	SSH::foo\x0a{ \x0aif (0 < SSH::i) \x0a\x09return (Foo);\x0aelse\x0a\x09return (Bar);\x0a\x0a}
T	-43	SSH::LOG	21	123	10.0.0.0/24	1.2.3.4	3.14	1315801931.273616	100.000000	hurz	2,4,1,3	CC,AA,BB	EMPTY	10,20,30	EMPTY	SSH::foo\x0a{ \x0aif (0 < SSH::i) \x0a\x09return (Foo);\x0aelse\x0a\x09return (Bar);\x0a\x0a}
@TEST-END-FILE
@TEST-START-FILE input3.log
#separator \x09
#path	ssh
#fields	b	i	e	c	p	sn	a	d	t	iv	s	sc	ss	se	vc	ve	f
#types	bool	int	enum	count	port	subnet	addr	double	time	interval	string	table	table	table	vector	vector	func
T	-42	SSH::LOG	21	123	10.0.0.0/24	1.2.3.4	3.14	1315801931.273616	100.000000	hurz	2,4,1,3	CC,AA,BB	EMPTY	10,20,30	EMPTY	SSH::foo\x0a{ \x0aif (0 < SSH::i) \x0a\x09return (Foo);\x0aelse\x0a\x09return (Bar);\x0a\x0a}
F	-43	SSH::LOG	21	123	10.0.0.0/24	1.2.3.4	3.14	1315801931.273616	100.000000	hurz	2,4,1,3	CC,AA,BB	EMPTY	10,20,30	EMPTY	SSH::foo\x0a{ \x0aif (0 < SSH::i) \x0a\x09return (Foo);\x0aelse\x0a\x09return (Bar);\x0a\x0a}
@TEST-END-FILE

@load frameworks/communication/listen

redef InputAscii::empty_field = "EMPTY";

module A;

export {
	redef enum Input::ID += { INPUT };
}

type Idx: record {
	i: int;
};

type Val: record {
	b: bool;
	e: Log::ID;
	c: count;
	p: port;
	sn: subnet;
	a: addr;
	d: double;
	t: time;
	iv: interval;
	s: string;
	sc: set[count];
	ss: set[string];
	se: set[string];
	vc: vector of int;
	ve: vector of int;
};

global servers: table[int] of Val = table();

global outfile: file;

global try: count;

event line(tpe: Input::Event, left: Idx, right: Val) {
	print outfile, "============EVENT============";
	print outfile, tpe;
	print outfile, left;
	print outfile, right;
}

event bro_init()
{
	outfile = open ("../out");
	try = 0;
	# first read in the old stuff into the table...
	Input::create_stream(A::INPUT, [$source="../input.log", $mode=Input::REREAD]);
	Input::add_tablefilter(A::INPUT, [$name="ssh", $idx=Idx, $val=Val, $destination=servers, $ev=line]);
}


event Input::update_finished(id: Input::ID) {
	print outfile, "==========SERVERS============";
	print outfile, servers;
	
	try = try + 1;
	if ( try == 3 ) {
		print outfile, "done";
		close(outfile);
		Input::remove_tablefilter(A::INPUT, "ssh");
		Input::remove_stream(A::INPUT);
	}
}