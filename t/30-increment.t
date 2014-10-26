#!perl -T

use strict;
use warnings;

use Test::Most 'bail', tests => 24;

use Net::Dogstatsd;


# Create an object to communicate with Dogstatsd, using default server/port settings.
my $dogstatsd = Net::Dogstatsd->new();

ok(
	defined( $dogstatsd ),
	'Net::Dogstatsd instance defined',
);

# test required argument
throws_ok(
	sub {
		$dogstatsd->increment();
	},
	qr/required argument/,
	'Increment: dies on missing required argument-metric name',
);



throws_ok(
	sub {
		$dogstatsd->increment(
			name => '1testmetric.request_count',
		);
	},
	qr/Invalid metric name/,
	'Increment: dies with invalid metric name  - starting with number',
);


warning_like(
	sub {
		$dogstatsd->increment(
			name => 'testmetric.request_count:',
		);
	},
	qr/converted metric/,
	'Increment: warns on translated metric name - colon',
) || diag ($dogstatsd );


warnings_exist(
	sub {
		$dogstatsd->increment(
			name => 'testmetric.request_count|',
		);
	},
	qr/converted metric/,
	'Increment: warns on translated metric name - pipe',
) || diag ($dogstatsd );


warnings_exist(
	sub {
		$dogstatsd->increment(
			name => 'testmetric.request_count@',
		);
	},
	qr/converted metric/,
	'Increment: warns on translated metric name - at sign',
) || diag ($dogstatsd );


throws_ok(
	sub {
		$dogstatsd->increment(
			name  => 'testmetric.request_count',
			value => 'abc',
		);
	},
	qr/positive integer/,
	'Increment: dies on non-numeric value',
);

throws_ok(
	sub {
		$dogstatsd->increment(
			name  => 'testmetric.request_count',
			value => ''
		);
	},
	qr/not a positive integer/,
	'Increment: dies with an empty value',
);

throws_ok(
	sub {
		$dogstatsd->increment(
			name  => 'testmetric.request_count',
			value => -1,
		);
	},
	qr/positive integer/,
	'Increment: dies on negative value',
);


throws_ok(
	sub {
		$dogstatsd->increment(
			name  => 'testmetric.request_count',
			value => 0.5,
		);
	},
	qr/positive integer/,
	'Increment: dies on float value',
) || diag ($dogstatsd );


lives_ok(
	sub {
		$dogstatsd->increment( name => 'testmetric.request_count' );
	},
	'Increment: specified metric name only',
) || diag ($dogstatsd );


lives_ok(
	sub {
		$dogstatsd->increment(
			name  => 'testmetric.request_count',
			value => 4,
		);
	},
	'Increment: specified metric name and value',
) || diag ($dogstatsd );

# Additional tag-specific tests

throws_ok(
	sub {
		$dogstatsd->increment(
			name => 'testmetric.request_count',
			tags => {},
		);
	},
	qr/Not an ARRAY reference/,
	'Increment: dies unless tag list is an arrayref',
);


throws_ok(
	sub {
		$dogstatsd->increment(
			name => 'testmetric.request_count',
			tags => [ '1tag:something:value' ],
		);
	},
	qr/Invalid tag/,
	'Increment: dies when tag list contains invalid item - tag starting with number',
);


throws_ok(
	sub {
		$dogstatsd->increment(
			name => 'testmetric.request_count',
			tags => [ 'tagabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz:value' ],
		);
	},
	qr/Invalid tag/,
	'Increment: dies when tag list contains invalid item - tag > 200 characters',
);


# This is a non-standard check, DataDog will allow it, but it will result in
# confusion and unusual behavior in UI/graphing
throws_ok(
	sub {
		$dogstatsd->increment(
			name => 'testmetric.request_count',
			tags => [ 'tag:something:value' ],
		);
	},
	qr/Invalid tag/,
	'Increment: dies when tag list contains invalid item - two colons',
);


lives_ok(
	sub {
		$dogstatsd->increment(
			name => 'testmetric.request_count',
			tags => [],
		);
	},
	'Increment: empty tag list',
) || diag ($dogstatsd );


warning_like(
	sub {
		$dogstatsd->increment(
			name => 'testmetric.request_count',
			tags => [ 'tag+name&here:value' ],
		);
	},
	qr/converted tag/,
	'Increment: tag list with invalid item - WARN on disallowed characters',
) || diag ($dogstatsd );


lives_ok(
	sub {
		$dogstatsd->increment(
			name => 'testmetric.request_count',
			tags => [ 'testingtag', 'testtag:testvalue' ]
		);
	},
	'Increment: valid tag list',
) || diag ($dogstatsd );


# Additional sample rate-specific tests

throws_ok(
	sub {
		$dogstatsd->increment(
			name        => 'testmetric.request_count',
			sample_rate => '',
		);
	},
	qr/Invalid sample rate/,
	'Increment: dies with empty sample_rate',
);


throws_ok(
	sub {
		$dogstatsd->increment(
			name        => 'testmetric.request_count',
			sample_rate => 2,
		);
	},
	qr/Invalid sample rate/,
	'Increment: dies with sample rate > 1',
);


dies_ok(
	sub {
		$dogstatsd->increment(
			name => 'testmetric.request_count',
			sample_rate => -1,
		);
	},
	'Increment: dies with negative sample rate',
);


throws_ok(
	sub {
		$dogstatsd->increment(
			name => 'testmetric.request_count',
			sample_rate => 0,
		);
	},
	qr/Invalid sample rate/,
	'Increment: dies with sample rate of zero',
);


lives_ok(
	sub {
		$dogstatsd->increment(
			name        => 'testmetric.request_count',
			sample_rate => 0.5,
		);
	},
	'Increment: valid sample rate',
) || diag ($dogstatsd );
